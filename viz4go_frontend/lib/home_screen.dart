import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:graphview/GraphView.dart';
import 'package:viz4go_frontend/widgets/node.dart';
import 'package:viz4go_frontend/widgets/viz4go_label.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Graph> graphs = [];
  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration(
  )
    ..siblingSeparation = 100
    ..levelSeparation  = 50
    ..subtreeSeparation = 100
    ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  List<dynamic> _items = [];

  Future<void> readJson() async {
    try {
      print('Loading data...');
      final String response =
          await rootBundle.loadString('found_paths_with_relations.json');
      final data = await json.decode(response);
      setState(() {
        _items = data;
        print('Data loaded');
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void loadGraph(list) {
    graphs.clear(); // Clear existing graphs before loading new ones
    for (int i = 0; i < list.length; i++) {
      final graph = Graph();
      final path = list[i];
      for (int j = 0; j < path.length; j++) {
        final node1 = Node.Id(path[j][0]);
        final node2 = Node.Id(path[j][1]);
        graph.addEdge(node1, node2);
      }
      graphs.add(graph);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[300],
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: graphs.isNotEmpty == true
                ? InteractiveViewer(
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(200),
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      width: double.maxFinite,
                      height: double.maxFinite,
                      child: Stack(
                        children: [
                          for (int i = 0; i < graphs.length; i++)
                            Positioned(
                              left: i * 150.0,
                              child: GraphView(
                                graph: graphs[i],
                                algorithm: BuchheimWalkerAlgorithm(
                                  builder,
                                  TreeEdgeRenderer(builder),
                                ),
                                paint: Paint()
                                  ..color = Colors.black
                                  ..strokeWidth = 1
                                  ..style = PaintingStyle.stroke,
                                builder: (node) =>
                                    NodeWidget(id: node.key!.value),
                              ),
                            )
                        ],
                      ),
                    ),
                  )
                : const Viz4goLabel()
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                width: 300, // Szerokość naszego "AppBar"
                decoration: BoxDecoration(
                  color: Colors.blueGrey[700], // Kolor tła "AppBar"
                  borderRadius: BorderRadius.circular(10), // Zaokrąglone rogi
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await readJson();
                        setState(() {
                          loadGraph(_items);
                        });
                      },
                      icon: const Icon(Icons.refresh,
                          color: Color.fromARGB(255, 237, 224, 219)),
                      label: const Text('Load data',
                          style: TextStyle(
                              color: Color.fromARGB(255, 237, 224, 219))),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      minLines: 5,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'GO id\'s',
                        labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 237, 224, 219)),
                        fillColor: Colors.blueGrey[300],
                        filled: true,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 237, 224, 219),
                              width: 2.0),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 237, 224, 219),
                              width: 2.0),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 237, 224, 219),
                              width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        print('clicked');
                      },
                      icon: const Icon(Icons.file_present_outlined,
                          color: Color.fromARGB(255, 237, 224, 219)),
                      label: const Text('Attach file',
                          style: TextStyle(
                              color: Color.fromARGB(255, 237, 224, 219))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
