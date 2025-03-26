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

  // Lista z informacjami o wszystkich węzłach (GOtermach)
  List<Node> _nodesData = [];

  // Mapa (idWęzła -> indeks w _positions)
  Map<String, int> _nodeIndex = {};

  // Pozycje węzłów
  List<ValueNotifier<Offset>> _positions = [];

  // Węzły podświetlone (hover)
  List<String> _hoveredNodes = [];

  // Mapa rodziców: klucz = ID dziecka, wartość = lista rodziców
  Map<String, List<String>> _parentsMap = {};

  // Zbiór aktualnie widocznych węzłów w hierarchii
  late Set<String> _visibleNodes;

  @override
  void initState() {
    super.initState();
    print(widget.levels);
    _visibleNodes = {};
  }

  @override
  Widget build(BuildContext context) {
    //final size = widget.proteinNodes[widget.entry.value].childGoTerms.length;
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
              ? 200
              : 50 + size * 1,
          height: widget.proteinNodes[widget.entry.value].isExpanded
              ? 200
              : 50 + size * 1,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 41, 115, 16).withOpacity(0.5),
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
                    if (isLoading)
                      const Center(
                        child: SizedBox(child: CircularProgressIndicator()),
                      )
                    else
                      /*
                      CustomPaint(
                        painter: LinePainter(
                          _positions,
                          _getVisibleConnections(),
                          _nodeIndex,
                          ['is_a','part_of','regulates','negatively_regulates'],
                          LayoutMode.tree,
                        ),
                        child: Container(),
                      ),
                      */
                      for (var entry in _nodeIndex.entries)
                        // Rysujemy tylko węzły, które są w widocznym zbiorze:
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
                                          (_hoveredNodes.contains(entry.key)),
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

  /// Ładuje lokalny graf i pozycjonuje węzły
  Future<void> loadLocalGraph(List<dynamic> list) async {
    setState(() {
      isLoading = true;
    });

    _positions.clear();
    _nodeIndex.clear();
    _parentsMap.clear();

    int index = 0;

    print('--- loadLocalGraph START (FLIP) ---');
    print('connections (liczba: ${list.length}):');
    for (var c in list) {
      print('  $c');
    }

    // Budujemy mapę indeksów _nodeIndex
    // Teraz zakładamy, że c[0] to PARENT, c[1] to CHILD
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

    print('Utworzone _nodeIndex: $_nodeIndex');

    // Wygeneruj pozycje
    _positions = PositionGenerator.generateTreePositions(
      _nodeIndex,
      widget.connections,
      const Rect.fromLTWH(40, 5, 100, 100),
      isSmall: true,
    );

    // Pobieramy info o węzłach z API
    final List<Node> nodesData =
        await ApiService().fetchGoTermsByNodeIndex(_nodeIndex);

    print('Z API przyszły węzły: ${nodesData.map((e) => e.id).toList()}');

    // Budujemy mapę rodziców
    // Który węzeł jest dzieckiem, a który rodzicem?
    // Skoro c[0] jest parent, a c[1] to child,
    // to w _parentsMap[child] dodajemy parenta.
    for (var n in nodesData) {
      _parentsMap[n.id] = [];
    }
    for (var c in list) {
      final parent = c[0];
      final child = c[1];
      if (!_parentsMap[child]!.contains(parent)) {
        _parentsMap[child]!.add(parent);
      }
    }

    print('_parentsMap: $_parentsMap');

    setState(() {
      _nodesData = nodesData;
      isLoading = false;
    });

    // Teraz, skoro c[0] jest parentem, to "liściem" będzie ten,
    // który NIGDY nie pojawia się w c[0].
    // Czyli najpierw zbudujemy zbiór parentSet (wszystkich c[0]):
    Set<String> parentSet = list.map((c) => c[0] as String).toSet();

    // Wszystkie węzły (klucze w _nodeIndex):
    Set<String> allNodes = _nodeIndex.keys.toSet();

    // Liście to takie, które nie występują w parentSet
    List<String> leafNodes = allNodes.difference(parentSet).toList();

    print('Zbiór parentSet: $parentSet');
    print('Wszystkie węzły: $allNodes');
    print('Lista liści: $leafNodes');

    // Wybieramy pierwszy liść (najbardziej szczegółowy)
    String? deepestNode = leafNodes.isNotEmpty ? leafNodes.first : null;

    // Na start wyświetlamy tylko ten najgłębszy
    if (deepestNode != null) {
      setState(() {
        _visibleNodes = {deepestNode};
      });
      print('Startowy (najbardziej szczegółowy) węzeł to: $deepestNode');
    }

    print('--- loadLocalGraph END (FLIP) ---');
  }

  /// Zwraca połączenia między wyłącznie widocznymi węzłami
  List<dynamic> _getVisibleConnections() {
    return widget.connections.where((c) {
      return _visibleNodes.contains(c[0]) && _visibleNodes.contains(c[1]);
    }).toList();
  }

  /// Po kliknięciu w węzeł - odsłaniamy jego rodziców
  void _handleNodeTap(String nodeId) {
    print('--- _handleNodeTap($nodeId) ---');
    print('Rodzice tego węzła: ${_parentsMap[nodeId]}');

    if (_parentsMap.containsKey(nodeId)) {
      _visibleNodes.addAll(_parentsMap[nodeId]!);
    }

    print('Po dodaniu rodziców, _visibleNodes = $_visibleNodes');

    setState(() {});
  }

  /// Podświetlanie (hover) węzłów:
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
