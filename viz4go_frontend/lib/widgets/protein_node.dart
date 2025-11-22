import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:viz4go_frontend/models/node.dart';
import 'package:viz4go_frontend/services/api_service.dart';
import 'package:viz4go_frontend/widgets/node.dart';
import 'package:viz4go_frontend/widgets/protein_node_line_painter.dart';
import '../models/protein_node.dart';
import '../services/position_generator.dart';

class ProteinNodeWidget extends StatefulWidget {
  final MapEntry<String, int> entry;
  final List<ValueNotifier<Offset>> positions;
  final List<ProteinNode> proteinNodes;
  final List<dynamic> connections;
  bool isVisible = true;
  final VoidCallback onDoubleTap;
  final List<List<String>> levels;
  final int selectedLevels;

  ProteinNodeWidget({
    super.key,
    required this.entry,
    required this.positions,
    required this.proteinNodes,
    required this.connections,
    required this.onDoubleTap,
    this.isVisible = true,
    required this.levels,
    required this.selectedLevels,
  });

  @override
  State<ProteinNodeWidget> createState() => _ProteinNodeWidgetState();
}

class _ProteinNodeWidgetState extends State<ProteinNodeWidget> {
  bool isLoading = false;
  List<Node> _nodesData = [];
  Map<String, int> _nodeIndex = {};
  List<ValueNotifier<Offset>> _positions = [];
  List<String> _hoveredNodes = [];
  late Set<String> _visibleNodes;
  List<List<String>> _levels = [];
  int _currentLevelIndex = 0;

  @override
  void initState() {
    super.initState();
    _visibleNodes = {};
  }

  @override
  Widget build(BuildContext context) {
    final size = 10;
    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _nodesData = [];
          loadLocalGraph(widget.connections);
        });
        widget.onDoubleTap();
      },
      child: Draggable(
        feedback: Container(),
        childWhenDragging: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.proteinNodes[widget.entry.value].isExpanded
              ? 200.0
              : 50.0 + size,
          height: widget.proteinNodes[widget.entry.value].isExpanded
              ? 200.0
              : 50.0 + size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:
                const Color.fromARGB(255, 41, 115, 16).withOpacity(0.5),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.entry.key.replaceAll(RegExp(r'.pdb'), ''),
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),
        ),
        onDragUpdate: (details) {
          widget.positions[widget.entry.value].value += details.delta;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.proteinNodes[widget.entry.value].isExpanded
              ? 200.0
              : 50.0 + size,
          height: widget.proteinNodes[widget.entry.value].isExpanded
              ? 200.0
              : 50.0 + size,
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 41, 115, 16),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: !widget.proteinNodes[widget.entry.value].isExpanded
              ? Center(
                  child: Text(
                    widget.entry.key.replaceAll(RegExp(r'.pdb'), ''),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (!isLoading)
                      CustomPaint(
                        painter: ProteinNodeLinePainter(
                          _positions,
                          _getVisibleConnections(),
                          _nodeIndex,
                        ),
                        size: Size.infinite,
                      ),
                    if (isLoading)
                      const Center(
                        child: SizedBox(child: CircularProgressIndicator()),
                      )
                    else
                      for (var entry in _nodeIndex.entries)
                        if (_visibleNodes.contains(entry.key))
                          ValueListenableBuilder<Offset>(
                            valueListenable: _positions[entry.value],
                            builder: (context, position, child) {
                              final node = _nodesData.firstWhere(
                                (n) => n.id == entry.key,
                                orElse: () => Node(id: entry.key, name: ''),
                              );
                              return Positioned(
                                left: position.dx,
                                top: position.dy,
                                child: GestureDetector(
                                  onTap: () => _handleNodeTap(node.id),
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
                                    child: NodeWidget(
                                      entry: entry,
                                      positions: _positions,
                                      nodeData: node,
                                      isVisible: _hoveredNodes.isEmpty ||
                                          _hoveredNodes.contains(entry.key),
                                      isSmall: true,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
        ),
      ),
    );
  }

  void _recenterTree() {
    if (_visibleNodes.isEmpty) return;

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final id in _visibleNodes) {
      final idx = _nodeIndex[id];
      if (idx == null) continue;
      final p = _positions[idx].value;
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }

    final Offset treeCenter = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    const Offset containerCenter = Offset(75, 75);

    final Offset delta = containerCenter - treeCenter;

    for (final n in _positions) {
      n.value += delta;
    }
  }

  Future<void> loadLocalGraph(List<dynamic> list) async {
    setState(() {
      isLoading = true;
    });

    _positions.clear();
    _nodeIndex.clear();

    int index = 0;

    for (var c in list) {
      final parent = c[0];
      final child = c[1];
      if (!_nodeIndex.containsKey(parent)) {
        _nodeIndex[parent] = index++;
      }
      if (!_nodeIndex.containsKey(child)) {
        _nodeIndex[child] = index++;
      }
    }

    _positions = PositionGenerator.generateTreePositions(
      _nodeIndex,
      widget.connections,
      const Rect.fromLTWH(20, 0, 140, 140),
      isSmall: true,
    );

    final List<Node> nodesData =
        await ApiService().fetchGoTermsByNodeIndex(_nodeIndex);

    setState(() {
      _nodesData = nodesData;
      isLoading = false;
    });

    _recenterTree();

    _levels = PositionGenerator.groupGOLevels(list);
    if (_levels.isNotEmpty) {
      _currentLevelIndex = _levels.length - widget.selectedLevels;
      if (_currentLevelIndex < 0) {
        _currentLevelIndex = 0;
      }
      _visibleNodes = _levels[_currentLevelIndex].toSet();
    } else {
      _visibleNodes = {};
    }
  }

  List<dynamic> _getVisibleConnections() {
    return widget.connections.where((c) {
      return _visibleNodes.contains(c[0]) && _visibleNodes.contains(c[1]);
    }).toList();
  }

  void _handleNodeTap(String nodeId) {
    if (_currentLevelIndex > 0) {
      int nextLevel = _currentLevelIndex - 1;
      _visibleNodes.addAll(_levels[nextLevel]);
      _currentLevelIndex = nextLevel;
      setState(() {
        _recenterTree();
      });
    } else {}
  }

  void _updateHoveredNodes(String hoveredNode) {
    final List<String> relatedNodes = [hoveredNode];

    for (var connection in widget.connections) {
      if (connection[0] == hoveredNode || connection[1] == hoveredNode) {
        relatedNodes.add(connection[0]);
        relatedNodes.add(connection[1]);
      }
    }

    setState(() {
      _hoveredNodes = relatedNodes.toSet().toList();
    });
  }
}
