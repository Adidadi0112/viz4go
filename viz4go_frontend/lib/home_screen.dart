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
  final List<ProteinNode> _proteinNodesData = [];
  int _selectedLevels = 1;
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
        SnackBar snackBar = SnackBar(
          content: Text(
              'No protein data available for index $_proteinIndex. Please check the data.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      setState(() {
        _items = _proteinAndConnections!.values.expand((e) => e).toList();
        _protein = "All proteins";
        _loadProteinGraph(_proteinAndConnections,
            selectedLevels: _selectedLevels);
      });
    }
  }

  Future<void> _loadProteinGraph(Map<String, dynamic>? proteinAndConnections,
      {int selectedLevels = 1}) async {
    setState(() => isLoading = true);

    _positions.clear();
    _nodeIndex = {};
    _proteinNodesData.clear();
    proteinEdges.clear();

    int index = 0;

    _proteinAndConnections!.forEach((protein, connections) {
      final levels = PositionGenerator.groupGOLevels(connections);

      _proteinNodesData.add(ProteinNode(
        id: protein,
        name: protein,
        isExpanded: false,
        levels: levels,
      ));

      _nodeIndex[protein] = index++;
    });

    final Map<String, List<String>> proteinToGo = {};
    _proteinAndConnections!.forEach((protein, connections) {
      final flatTerms = PositionGenerator.groupGOLevels(connections)
          .expand((lvl) => lvl)
          .cast<String>()
          .toSet()
          .toList();
      proteinToGo[protein] = flatTerms;
    });

    Map<String, int> clusters = {};
    List<dynamic> clusterEdges = [];

    try {
      final result = await ApiService().fetchProteinClusters(
        proteinToGo,
        mode: "semantic",
        measure: "wang",
        threshold: 0.6,
        algo: "louvain",
        resolution: 1.0,
      );
      clusters = result['clusters'] as Map<String, int>;
      clusterEdges = result['edges'] as List<dynamic>;

      debugPrint("✅ Otrzymano ${clusterEdges.length} krawędzi z klasteryzacji");
    } catch (e) {
      debugPrint("Cluster fetch failed → fallback random layout: $e");
    }

    // Użyj krawędzi z klasteryzacji zamiast obliczać własne
    for (var edge in clusterEdges) {
      final source = edge['source'] as String;
      final target = edge['target'] as String;
      final weight = edge['weight'] as num;

      // Dodaj krawędź (możesz filtrować po wadze, jeśli chcesz)
      if (weight >= 0.4) {
        // Opcjonalny próg do wizualizacji
        proteinEdges[source] = [target, weight.toDouble()];
      }
    }

    _positions = PositionGenerator.generateClusteredPositions(
      clusters,
      _nodeIndex,
      const Rect.fromLTWH(0, 0, 1600, 1200),
    );

    _nodesData =
        _proteinAndConnections!.keys.map((p) => Node(id: p, name: p)).toList();

    setState(() => isLoading = false);
  }

  Set<String> _getSelectedTerms(List<List<String>> levels, int selectedLevels) {
    final int startIndex =
        levels.length - selectedLevels < 0 ? 0 : levels.length - selectedLevels;
    final selectedTerms = <String>{};
    for (int i = startIndex; i < levels.length; i++) {
      selectedTerms.addAll(levels[i]);
    }
    return selectedTerms;
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
                                              levels:
                                                  _proteinNodesData[entry.value]
                                                      .levels,
                                              selectedLevels: _selectedLevels,
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
                  : Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            backgroundColor: Colors.blueGrey[700],
                            child: IconButton(
                              icon: const Icon(Icons.fullscreen_exit,
                                  color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _isEverythingProteins =
                                      !_isEverythingProteins;
                                  _updateProteinData();
                                });
                              },
                            ),
                          ),
                        ),
                        Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.blueGrey[700],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    _selectedLevels.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const Divider(
                                  color: Colors.white,
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedLevels++;
                                      _loadProteinGraph(_proteinAndConnections,
                                          selectedLevels: _selectedLevels);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                                const Divider(
                                  color: Colors.white,
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedLevels--;
                                      _loadProteinGraph(_proteinAndConnections,
                                          selectedLevels: _selectedLevels);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.remove,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ))
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
