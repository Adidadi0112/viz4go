import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:viz4go_frontend/widgets/line_painter.dart';
import 'package:viz4go_frontend/widgets/node.dart';
import 'package:viz4go_frontend/widgets/viz4go_label.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<List<ValueNotifier<Offset>>> _positions = [];
  List<List<dynamic>> _connections = [];
  List<dynamic> _items = [];

  Future<void> readJson() async {
    try {
      print('Loading data...');
      final String response = await rootBundle.loadString('example.json');
      final data = await json.decode(response);
      setState(() {
        _items = data;
        print('Data loaded');
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void loadGraph(List<dynamic> list) {
    _connections.clear();
    _positions.clear();
    for (int i = 0; i < list.length; i++) {
      final graph = list[i];
      final graphConnections = [];
      for (int j = 0; j < graph.length; j++) {
        final node1 = graph[j][0];
        final node2 = graph[j][1];
        final relation = graph[j][2];
        graphConnections.add([node1, node2, relation]);
      }
      _connections.add(graphConnections);
      final graphPositions = _generateCircularPositions(
          graphConnections.length, 200, Offset(i * 300 + 150, 300));
      _positions.add(graphPositions);
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
              child: _connections.isNotEmpty == true
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
                            // TODO: Repair CustomPainter and resolve data structore
                            for (int i = 0; i < _connections.length; i++)
                              CustomPaint(
                                painter: LinePainter(_positions[i], _connections),
                              ),
                            for (int i = 0; i < _connections.length; i++)
                              for (int j = 0; j < _positions[i].length; j++)
                                ValueListenableBuilder<Offset>(
                                  valueListenable: _positions[i][j],
                                  builder: (context, position, child) {
                                    return Positioned(
                                      left: position.dx,
                                      top: position.dy,
                                      child: Draggable(
                                        feedback: Container(
                                          width: 70,
                                          height: 50,
                                          color: Colors.blue.withOpacity(0.5),
                                        ),
                                        childWhenDragging: Container(),
                                        onDragUpdate: (details) {
                                          _positions[i][j].value +=
                                              details.delta;
                                        },
                                        child: Container(
                                          width: 70,
                                          height: 50,
                                          color: Colors.blue,
                                          child: Center(
                                            child: Text(
                                              _connections[i][j][0],
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                    )
                  : const Viz4goLabel()),
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

List<ValueNotifier<Offset>> _generateCircularPositions(
    int count, double radius, Offset center) {
  return List.generate(count, (index) {
    final angle = 2 * pi * index / count;
    final offset = Offset(
        center.dx + radius * cos(angle), center.dy + radius * sin(angle));
    return ValueNotifier<Offset>(offset);
  });
}
