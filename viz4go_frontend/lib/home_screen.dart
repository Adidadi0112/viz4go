import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:viz4go_frontend/models/node.dart';
import 'package:viz4go_frontend/widgets/line_painter.dart';
import 'package:viz4go_frontend/widgets/menu.dart';
import 'package:viz4go_frontend/widgets/node.dart';
import 'package:viz4go_frontend/widgets/viz4go_label.dart';
import 'package:viz4go_frontend/services/api_service.dart';
import 'package:viz4go_frontend/services/position_generator.dart';

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
  LayoutMode _currentLayoutMode = LayoutMode.random;
  final TextEditingController _goIdController = TextEditingController();
  String _protein = '';
  bool isLoading = false;
  bool isCsv = false;
  List<String> _hoveredNodes =
      []; // Nowa zmienna do śledzenia najechanego węzła

  void _generateGraphFromTextField(List<dynamic> newItems) {
    // TO DO umoliwić wrzucenie tylko jednego pliku .csv, albbo dwóch
    setState(() {
      _items = newItems;
      isCsv = false;
    });
    loadGraph(_items);
  }

  void _generateGraphFromCsv(Map<String, dynamic>? connectionsCsv) {
    setState(() {
      isCsv = true;
      _items = connectionsCsv!.values.first;
      _protein = connectionsCsv.keys.first;
    });
    loadGraph(_items);
  }

  Future<void> readJson() async {
    try {
      final String response = await rootBundle.loadString('connections.json');
      final data = await json.decode(response);
      setState(() {
        _items = data;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void _updateLayoutMode(LayoutMode newMode) {
    setState(() {
      _currentLayoutMode = newMode;
      _positions = _generatePositions(
          _nodeIndex.length, const Rect.fromLTWH(0, 0, 800, 700));
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
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.maxFinite,
                        height: double.maxFinite,
                        child: Stack(
                          children: [
                            CustomPaint(
                              painter: LinePainter(
                                  _positions,
                                  _items,
                                  _nodeIndex,
                                  _activeFilters,
                                  _currentLayoutMode),
                              child: Container(),
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
                                          ;
                                        });
                                      },
                                      onExit: (_) {
                                        setState(() {
                                          _hoveredNodes = [];
                                        });
                                      },
                                      child: NodeWidget(
                                        entry: entry,
                                        positions: _positions,
                                        nodeData: node,
                                        isVisible: _hoveredNodes.isEmpty ||
                                            (_hoveredNodes.contains(entry.key)),
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
          isCsv
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(_protein),
                    ),
                  ))
              : const Align(),
        ],
      ),
    );
  }
}
