import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:viz4go_frontend/widgets/line_painter.dart';
import 'package:viz4go_frontend/widgets/node.dart';
import 'package:viz4go_frontend/widgets/viz4go_label.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ValueNotifier<Offset>> _positions = [];
  late final Map<String, int> _nodeIndex;
  List<dynamic> _items = [];


  Future<void> readJson() async {
    try {
      print('Loading data...');
      final String response = await rootBundle.loadString('connections.json');
      final data = await json.decode(response);
      setState(() {
        _items = data;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<List<Map<String, String>>> loadCsvData() async {
  final data = await rootBundle.loadString('assets/go_nodes.csv');
  List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);

  List<Map<String, String>> csvData = [];
  List<String> headers = csvTable[0].map((e) => e.toString()).toList();

  for (var i = 1; i < csvTable.length; i++) {
    Map<String, String> row = {};
    for (var j = 0; j < headers.length; j++) {
      row[headers[j]] = csvTable[i][j].toString();
    }
    csvData.add(row);
  }
  print(csvData);
  return csvData;
}

  void loadGraph(List<dynamic> list) {
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
    _positions = _generateRandomPositions(
        _nodeIndex.length, const Rect.fromLTWH(200, 100, 500, 500));
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
              child: _items.isNotEmpty == true
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
                            CustomPaint(
                              painter:
                                  LinePainter(_positions, _items, _nodeIndex),
                              child: Container(),
                            ),
                            for (var entry in _nodeIndex.entries)
                              ValueListenableBuilder<Offset>(
                                  valueListenable: _positions[entry.value],
                                  builder: (context, position, child) {
                                    return Positioned(
                                      left: position.dx,
                                      top: position.dy,
                                      child: NodeWidget(
                                        entry: entry,
                                        positions: _positions,
                                      ),
                                    );
                                  })
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

List<ValueNotifier<Offset>> _generateRandomPositions(int count, Rect area) {
  final random = Random();
  return List.generate(count, (index) {
    final x = random.nextDouble() * area.width + area.left;
    final y = random.nextDouble() * area.height + area.top;
    return ValueNotifier<Offset>(Offset(x, y));
  });
}
