import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:viz4go_frontend/models/Node.dart';
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
  late final Map<String, int> _nodeIndex;
  List<dynamic> _items = [];
  final List<String> _activeFilters = ['is_a', 'part_of'];
  List<Node> _nodesData = [];
  LayoutMode _currentLayoutMode = LayoutMode.random;
  final TextEditingController _goIdController = TextEditingController();
  bool isLoading = false;

  void _generateGraphFromTextField(List<dynamic> newItems) {
    setState(() {
      _items = newItems;
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

  TransformationController _transformationController =
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
                              painter: LinePainter(_positions, _items,
                                  _nodeIndex, _activeFilters),
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
                                    child: NodeWidget(
                                      entry: entry,
                                      positions: _positions,
                                      nodeData: node,
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
          ),
        ],
      ),
    );
  }
}
