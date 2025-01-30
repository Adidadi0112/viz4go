import 'package:flutter/material.dart';
import 'package:viz4go_frontend/home_screen.dart';
import 'package:viz4go_frontend/models/node.dart';
import 'package:viz4go_frontend/services/api_service.dart';
import 'package:viz4go_frontend/widgets/line_painter.dart';
import 'package:viz4go_frontend/widgets/node.dart';
import '../models/protein_node.dart';
import '../services/position_generator.dart';

class ProteinNodeWidget extends StatefulWidget {
  final MapEntry<String, int> entry;
  final List<ValueNotifier<Offset>> positions;
  final List<ProteinNode> proteinNodes;
  final List<dynamic> connections;
  bool isVisible = true;
  final VoidCallback onDoubleTap;

  ProteinNodeWidget(
      {super.key,
      required this.entry,
      required this.positions,
      required this.proteinNodes,
      required this.connections,
      required this.onDoubleTap,
      this.isVisible = true});

  @override
  State<ProteinNodeWidget> createState() => _ProteinNodeWidgetState();
}

class _ProteinNodeWidgetState extends State<ProteinNodeWidget> {
  bool isLoading = false;
  List<Node> _nodesData = [];
  Map<String, int> _nodeIndex = {};
  List<ValueNotifier<Offset>> _positions = [];
  List<String> _hoveredNodes = [];

  @override
  Widget build(BuildContext context) {
    final size = widget.proteinNodes[widget.entry.value].childGoTerms.length;
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
              ? 200
              : 50 + size * 1,
          height: widget.proteinNodes[widget.entry.value].isExpanded
              ? 200
              : 50 + size * 1,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 41, 115, 16)
                .withOpacity(0.5), // Kolor podczas przeciągania
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
              ? 200
              : 50 + size * 1,
          height: widget.proteinNodes[widget.entry.value].isExpanded
              ? 200
              : 50 + size * 1,
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color:
                Color.fromARGB(255, 41, 115, 16), // Kolor zależny od namespace
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
                        fontWeight: FontWeight.bold),
                  ),
                )
              : Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (isLoading)
                      const Center(
                        child: SizedBox(child: CircularProgressIndicator()),
                      )
                    else
                      // CustomPaint(
                      //   painter: LinePainter(
                      //       _positions,
                      //       widget.connections,
                      //       _nodeIndex,
                      //       [
                      //         'is_a',
                      //         'part_of',
                      //         'regulates',
                      //         'negatively_regulates'
                      //       ],
                      //       LayoutMode.tree),
                      //   child: Container(),
                      // ),
                      for (var entry in _nodeIndex.entries)
                        ValueListenableBuilder<Offset>(
                          valueListenable: _positions[entry.value],
                          builder: (context, position, child) {
                            final node =
                                _nodesData.firstWhere((n) => n.id == entry.key);
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
                                child: NodeWidget(
                                  entry: entry,
                                  positions: _positions,
                                  nodeData: node,
                                  isVisible: _hoveredNodes.isEmpty ||
                                      (_hoveredNodes.contains(entry.key)),
                                  isSmall: true,
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

  Future<void> loadLocalGraph(List<dynamic> list) async {
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
    _positions = PositionGenerator.generateTreePositions(
        _nodeIndex, widget.connections, const Rect.fromLTWH(40, 5, 100, 100),
        isSmall: true);
    final List<Node> nodesData =
        await ApiService().fetchGoTermsByNodeIndex(_nodeIndex);
    setState(() {
      _nodesData = nodesData;
      isLoading = false;
    });
  }

  void _updateHoveredNodes(String hoveredNode) {
    final List<String> relatedNodes = [hoveredNode];

    // Znajdź wszystkie powiązane węzły (dzieci i rodzice)
    for (var connection in widget.connections) {
      if (connection[0] == hoveredNode || connection[1] == hoveredNode) {
        relatedNodes.add(connection[0]);
        relatedNodes.add(connection[1]);
      }
    }
    setState(() {
      _hoveredNodes = relatedNodes.toSet().toList(); // Usuń duplikaty
    });
  }
}
