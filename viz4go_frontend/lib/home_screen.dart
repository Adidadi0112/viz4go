import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:viz4go_frontend/models/node.dart';
import 'package:viz4go_frontend/widgets/line_painter.dart';
import 'package:viz4go_frontend/widgets/menu.dart';
import 'package:viz4go_frontend/widgets/node.dart';
import 'package:viz4go_frontend/widgets/protein_node.dart';
import 'package:viz4go_frontend/widgets/viz4go_label.dart';
import 'package:viz4go_frontend/services/api_service.dart';
import 'package:viz4go_frontend/services/position_generator.dart';

import 'models/protein_node.dart';
import 'widgets/protein_painter.dart';

enum LayoutMode { random, circular, twoColumn, tree }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ValueNotifier<Offset>> _positions = [];
  Map<String, int> _nodeIndex = {};
  List<dynamic> _items = [];
  final List<String> _activeFilters = ['is_a', 'part_of'];
  List<Node> _nodesData = [];
  List<ProteinNode> _proteinNodesData = [];
  final Map<String, List<dynamic>> proteinEdges = {};
  LayoutMode _currentLayoutMode = LayoutMode.random;
  final TextEditingController _goIdController = TextEditingController();
  String _protein = '';
  bool isLoading = false;
  bool isCsv = false;
  List<String> _hoveredNodes = [];
  Flutter3DController controller = Flutter3DController();
  int _proteinIndex = 1;
  Map<String, dynamic>? _proteinAndConnections;
  bool _isEverythingProteins = false;

  void _generateGraphFromTextField(List<dynamic> newItems) {
    // TO DO umoliwić wrzucenie tylko jednego pliku .csv, albo dwóch
    setState(() {
      _items = newItems;
      isCsv = false;
    });
    loadGraph(_items);
  }

  void _generateGraphFromCsv(Map<String, dynamic>? connectionsCsv) {
    setState(() {
      isCsv = true;
      _proteinAndConnections = connectionsCsv;
      _items = connectionsCsv!.values.elementAt(_proteinIndex);
      _protein = connectionsCsv.keys.elementAt(_proteinIndex);
    });
    loadGraph(_items);
  }

  void _updateProteinData() {
    if (_isEverythingProteins == false) {
      if (_proteinAndConnections != null &&
          _proteinIndex >= 0 &&
          _proteinIndex < _proteinAndConnections!.keys.length) {
        setState(() {
          _protein = _proteinAndConnections!.keys.elementAt(_proteinIndex);
          _items = _proteinAndConnections!.values.elementAt(_proteinIndex);
          loadGraph(_items);
        });
      } else {
        print('Brak danych lub index poza zakresem!');
      }
    } else {
      setState(() {
        _items = _proteinAndConnections!.values.expand((e) => e).toList();
        _protein = "All proteins";
        _loadProteinGraph(_proteinAndConnections);
      });
    }
  }

  List<Offset> _calculateGoTermPositions(Offset center, int count) {
    const double radius = 100.0;
    final double angleStep = 2 * pi / count;
    return List.generate(count, (i) {
      final angle = angleStep * i;
      return center +
          Offset(
            radius * cos(angle),
            radius * sin(angle),
          );
    });
  }

  void _loadProteinGraph(Map<String, dynamic>? proteinAndConnections) {
    setState(() {
      isLoading = true;
    });

    // Wyczyść stare dane
    _positions.clear();
    _nodeIndex = {};
    int index = 0;

    _proteinAndConnections!.forEach(
      (protein, connections) {
        final goTerms =
            connections.expand((c) => [c[0], c[1]]).toSet().toList();
        _proteinNodesData.add(ProteinNode(
            id: protein,
            name: protein,
            isExpanded: false,
            childGoTerms: goTerms));
      },
    );
    for (int i = 0; i <= _proteinNodesData.length - 1; i++) {
      for (int j = 0; j <= _proteinNodesData.length - 2; j++) {
        final int commonGoTerms = _proteinNodesData[i]
            .childGoTerms
            .toSet()
            .intersection(_proteinNodesData[j + 1].childGoTerms.toSet())
            .length;
        if (commonGoTerms > 0) {
          proteinEdges[_proteinNodesData[i].id] = [
            _proteinNodesData[j].id,
            commonGoTerms
          ];
        }
      }
    }
    if (proteinAndConnections != null) {
      for (String proteinName in proteinAndConnections.keys) {
        if (!_nodeIndex.containsKey(proteinName)) {
          _nodeIndex[proteinName] = index++;
        }
      }
    }

    // Teraz wygeneruj losowe pozycje w obszarze 800x700
    _positions = PositionGenerator.generateRandomPositions(
      _nodeIndex.length,
      const Rect.fromLTWH(0, 0, 1000, 1000),
    );
    final List<Node> proteinNodesData =
        proteinAndConnections?.keys.map((proteinName) {
              return Node(
                id: proteinName,
                name: proteinName,
              );
            }).toList() ??
            [];

    setState(() {
      _nodesData = proteinNodesData;
      isLoading = false;
    });
  }

  void _decrementProteinIndex() {
    if (_proteinIndex > 0) {
      setState(() {
        _proteinIndex--;
        _updateProteinData();
      });
    }
  }

  void _incrementProteinIndex() {
    if (_proteinAndConnections != null &&
        _proteinIndex < _proteinAndConnections!.keys.length - 1) {
      setState(() {
        _proteinIndex++;
        _updateProteinData();
      });
    }
  }

  void _updateLayoutMode(LayoutMode newMode) {
    setState(() {
      _currentLayoutMode = newMode;
      _positions = _generatePositions(
          _nodeIndex.length, const Rect.fromLTWH(0, 0, 1500, 1000));
    });
  }

  List<ValueNotifier<Offset>> _generatePositions(int count, Rect area) {
    switch (_currentLayoutMode) {
      case LayoutMode.random:
        return PositionGenerator.generateRandomPositions(count, area);
      case LayoutMode.circular:
        return PositionGenerator.generateCircularPositions(
            count, area, 0.4, 0.8);
      case LayoutMode.twoColumn:
        return PositionGenerator.generateTwoColumnPositions(
            count, const Rect.fromLTWH(0, 0, 800, 1500));
      case LayoutMode.tree:
        return PositionGenerator.generateTreePositions(
            _nodeIndex, _items, area);
    }
  }

  void _updateHoveredNodes(String hoveredNode) {
    final List<String> relatedNodes = [hoveredNode];

    // Znajdź wszystkie powiązane węzły (dzieci i rodzice)
    for (var connection in _items) {
      if (connection[0] == hoveredNode || connection[1] == hoveredNode) {
        relatedNodes.add(connection[0]);
        relatedNodes.add(connection[1]);
      }
    }
    setState(() {
      _hoveredNodes = relatedNodes.toSet().toList(); // Usuń duplikaty
    });
  }

  Future<void> loadGraph(List<dynamic> list) async {
    setState(() {
      isLoading = true;
    });
    _positions.clear();
    _nodeIndex = {};
    int index = 0;
    for (var connection in list) {
      if (!_nodeIndex.containsKey(connection[0])) {
        _nodeIndex[connection[0]] = index++;
      }
      if (!_nodeIndex.containsKey(connection[1])) {
        _nodeIndex[connection[1]] = index++;
      }
    }
    _positions = PositionGenerator.generateRandomPositions(
        _nodeIndex.length, const Rect.fromLTWH(0, 0, 800, 700));
    final List<Node> nodesData =
        await ApiService().fetchGoTermsByNodeIndex(_nodeIndex);
    setState(() {
      _nodesData = nodesData;
      isLoading = false;
    });
  }

  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity()
      ..translate(-2000.0, -2000.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[300],
      body: Stack(
        children: [
          if (isLoading)
            const Center(
              child: SizedBox(
                  height: 200, width: 200, child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: _items.isNotEmpty
                  ? InteractiveViewer(
                      transformationController: _transformationController,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(2000),
                      minScale: 0.1,
                      maxScale: 10.0,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.maxFinite,
                        height: double.maxFinite,
                        child: Stack(
                          children: [
                            !_isEverythingProteins
                                ? CustomPaint(
                                    painter: LinePainter(
                                        _positions,
                                        _items,
                                        _nodeIndex,
                                        _activeFilters,
                                        _currentLayoutMode),
                                    child: Container(),
                                  )
                                : CustomPaint(
                                    painter: ProteinPainter(
                                        _positions,
                                        proteinEdges,
                                        _nodeIndex,
                                        _activeFilters,
                                        _currentLayoutMode),
                                  ),
                            for (var entry in _nodeIndex.entries)
                              ValueListenableBuilder<Offset>(
                                valueListenable: _positions[entry.value],
                                builder: (context, position, child) {
                                  final node = _nodesData
                                      .firstWhere((n) => n.id == entry.key);
                                  return Positioned(
                                    left: position.dx,
                                    top: position.dy,
                                    child: MouseRegion(
                                      onEnter: (event) {
                                        setState(() {
                                          _updateHoveredNodes(entry.key);
                                        });
                                      },
                                      onExit: (_) {
                                        setState(() {
                                          _hoveredNodes = [];
                                        });
                                      },
                                      child: !_isEverythingProteins
                                          ? NodeWidget(
                                              entry: entry,
                                              positions: _positions,
                                              nodeData: node,
                                              isVisible:
                                                  _hoveredNodes.isEmpty ||
                                                      (_hoveredNodes
                                                          .contains(entry.key)),
                                            )
                                          : ProteinNodeWidget(
                                              entry: entry,
                                              positions: _positions,
                                              proteinNodes: _proteinNodesData,
                                              connections:
                                                  _proteinAndConnections![
                                                      entry.key],
                                              isVisible:
                                                  _hoveredNodes.isEmpty ||
                                                      (_hoveredNodes
                                                          .contains(entry.key)),
                                              onDoubleTap: () {
                                                setState(() {
                                                  _proteinNodesData[entry.value]
                                                          .isExpanded =
                                                      !_proteinNodesData[
                                                              entry.value]
                                                          .isExpanded;
                                                });
                                              },
                                            ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    )
                  : const Viz4goLabel(),
            ),
          MenuWidget(
            onLoadData: () async {
              setState(() {
                loadGraph(_items);
              });
            },
            goIdController: _goIdController,
            activeFilters: _activeFilters,
            onLayoutModeChanged: _updateLayoutMode,
            onConnectionsUpdated: _generateGraphFromTextField,
            onCsvConnectionsUpdated: _generateGraphFromCsv,
          ),
          if (isCsv && _proteinAndConnections != null)
            Align(
              alignment: Alignment.bottomLeft,
              child: !_isEverythingProteins
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _decrementProteinIndex,
                                  icon: const Icon(Icons.chevron_left,
                                      color: Colors.white),
                                ),
                                Text(
                                  _protein,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                IconButton(
                                  onPressed: _incrementProteinIndex,
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEverythingProteins =
                                          !_isEverythingProteins;
                                      _updateProteinData();
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),
                            Flexible(
                              flex: 1,
                              child: Flutter3DViewer(
                                activeGestureInterceptor: true,
                                progressBarColor: Colors.orange,
                                enableTouch: true,
                                onProgress: (double progressValue) {
                                  debugPrint(
                                      'model loading progress : $progressValue');
                                },
                                onLoad: (String modelAddress) {
                                  debugPrint('model loaded : $modelAddress');
                                },
                                onError: (String error) {
                                  debugPrint('model failed to load : $error');
                                },
                                controller: controller,
                                src: 'assets/example.gltf',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        backgroundColor: Colors.blueGrey[700],
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen_exit,
                              color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isEverythingProteins = !_isEverythingProteins;
                              _updateProteinData();
                            });
                          },
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
