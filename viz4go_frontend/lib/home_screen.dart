import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:viz4go_frontend/widgets/line_painter.dart';
import 'package:viz4go_frontend/widgets/menu.dart';
import 'package:viz4go_frontend/widgets/node.dart';
import 'package:viz4go_frontend/widgets/viz4go_label.dart';

enum LayoutMode { random, circular, twoColumn }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ValueNotifier<Offset>> _positions = [];
  late final Map<String, int> _nodeIndex;
  List<dynamic> _items = [];
  List<String> _activeFilters = ['is_a', 'part_of'];
  LayoutMode _currentLayoutMode = LayoutMode.random;
  final TextEditingController _goIdController = TextEditingController();

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

  void _updateLayoutMode(LayoutMode newMode) {
  setState(() {
    _currentLayoutMode = newMode;
    _positions = _generatePositions(_nodeIndex.length, const Rect.fromLTWH(0, 0, 800, 700));
  });
}

List<ValueNotifier<Offset>> _generatePositions(int count, Rect area) {
  switch (_currentLayoutMode) {
    case LayoutMode.random:
      return _generateRandomPositions(count, area);
    case LayoutMode.circular:
      return _generateCircularPositions(count, area, 0.4, 0.8);
    case LayoutMode.twoColumn:
      return _generateTwoColumnPositions(count, const Rect.fromLTWH(0, 0, 800, 1500));
  }
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
    _positions = _generateRandomPositions(_nodeIndex.length, const Rect.fromLTWH(0, 0, 800, 700));
  }

  @override
  void initState() {
    
    super.initState();
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
                              painter: LinePainter(
                                  _positions, _items, _nodeIndex, _activeFilters),
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
                                },
                              )
                          ],
                        ),
                      ),
                    )
                  : const Viz4goLabel()),
          MenuWidget(
            onLoadData: () async {
              await readJson();
              setState(() {
                loadGraph(_items);
              });
            },
            goIdController: _goIdController,
            activeFilters: _activeFilters,
            onLayoutModeChanged: _updateLayoutMode,
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

List<ValueNotifier<Offset>> _generateCircularPositions(int count, Rect area, double innerRadiusRatio, double outerRadiusRatio) {
  final random = Random();
  final center = Offset(area.left + area.width / 2, area.top + area.height / 2);
  final innerRadius = min(area.width, area.height) * innerRadiusRatio / 2;
  final outerRadius = min(area.width, area.height) * outerRadiusRatio / 2;

  List<ValueNotifier<Offset>> positions = [];
  int innerCount = (count * 0.5).toInt(); 
  int outerCount = count - innerCount; 

  for (int i = 0; i < innerCount; i++) {
    double angle = random.nextDouble() * 2 * pi;
    double radius = innerRadius;
    double x = center.dx + radius * cos(angle);
    double y = center.dy + radius * sin(angle);
    positions.add(ValueNotifier<Offset>(Offset(x, y)));
  }

  for (int i = 0; i < outerCount; i++) {
    double angle = random.nextDouble() * 2 * pi;
    double radius = outerRadius;
    double x = center.dx + radius * cos(angle);
    double y = center.dy + radius * sin(angle);
    positions.add(ValueNotifier<Offset>(Offset(x, y)));
  }

  return positions;
}

List<ValueNotifier<Offset>> _generateTwoColumnPositions(int count, Rect area) {
  final double columnWidth = area.width / 2; 
  const double padding = 100.0; 
  final double columnHeight = area.height; 

  List<ValueNotifier<Offset>> positions = [];
  
  int columnCount = (count / 2).ceil(); 
  int halfCount = count - columnCount;

  for (int i = 0; i < columnCount; i++) {
    double x = area.left + columnWidth / 2 - padding;
    double y = area.top + i * (columnHeight / columnCount);
    positions.add(ValueNotifier<Offset>(Offset(x, y)));
  }

  for (int i = 0; i < halfCount; i++) {
    double x = area.left + columnWidth + padding;
    double y = area.top + i * (columnHeight / halfCount);
    positions.add(ValueNotifier<Offset>(Offset(x, y)));
  }

  return positions;
}

