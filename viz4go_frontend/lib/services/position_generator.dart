import 'dart:math';
import 'package:flutter/material.dart';
import 'package:viz4go_frontend/models/tree_node.dart';

class PositionGenerator {
  static List<ValueNotifier<Offset>> generateTreePositions(
      Map<String, int> nodeIndex, List<dynamic> items, Rect area) {
    Map<String, TreeNode> treeNodes = {};

    // Budowanie drzewa węzłów
    try {
      for (var connection in items) {
        if (connection is List && connection.length >= 2) {
          final parent = connection[0] as String;
          final child = connection[1] as String;
          if (!treeNodes.containsKey(parent)) {
            treeNodes[parent] = TreeNode(parent);
          }
          if (!treeNodes.containsKey(child)) {
            treeNodes[child] = TreeNode(child);
          }

          treeNodes[parent]!.children.add(child);
        }
      }
    } catch (e) {
      print('Error: $e');
    }

    List<ValueNotifier<Offset>> positions = List.generate(
        nodeIndex.length, (_) => ValueNotifier<Offset>(Offset.zero));

    // Szerokość wierzchołka
    const double nodeWidth = 125.0;
    const double nodeHeight = 80.0;
    const double verticalSpacing = 100.0;

    void setPosition(String nodeId, double x, double y, double dx,
        Map<String, TreeNode> nodes) {
      final index = nodeIndex[nodeId]!;
      positions[index].value = Offset(x + 2000, y + 2000);

      final children = nodes[nodeId]!.children;
      if (children.isNotEmpty) {
        int childCount = children.length;

        // Zapewnienie, że odstęp między wierzchołkami jest co najmniej równy szerokości węzła
        double adjustedDx = max(dx, nodeWidth * 1.5);

        for (var i = 0; i < children.length; i++) {
          double childX = x + (i - (children.length - 1) / 2) * adjustedDx;
          // Odwrócenie pozycji w osi Y (odmienne niż standardowe ustawienie)
          setPosition(
              children[i],
              childX,
              y -
                  (nodeHeight +
                      verticalSpacing), // Przemieszczanie wierzchołków w górę
              adjustedDx / 2,
              nodes);
        }
      }
    }

    // Znalezienie korzenia
    String root =
        treeNodes.keys.firstWhere((id) => !items.any((item) => item[1] == id));

    // Ustawienie pozycji korzenia na dole obszaru
    setPosition(
        root, area.width / 2, area.height - 50, area.width / 4, treeNodes);

    return positions;
  }

  static List<ValueNotifier<Offset>> generateRandomPositions(
      int count, Rect area) {
    final random = Random();
    return List.generate(count, (index) {
      final x = random.nextDouble() * area.width + area.left + 2000;
      final y = random.nextDouble() * area.height + area.top + 2000;
      return ValueNotifier<Offset>(Offset(x, y));
    });
  }

  static List<ValueNotifier<Offset>> generateCircularPositions(
      int count, Rect area, double innerRadiusRatio, double outerRadiusRatio) {
    final random = Random();
    final center =
        Offset(area.left + area.width / 2, area.top + area.height / 2);
    final innerRadius = min(area.width, area.height) * innerRadiusRatio / 2;
    final outerRadius = min(area.width, area.height) * outerRadiusRatio / 2;

    List<ValueNotifier<Offset>> positions = [];
    int innerCount = (count * 0.5).toInt();
    int outerCount = count - innerCount;

    for (int i = 0; i < innerCount; i++) {
      double angle = random.nextDouble() * 2 * pi;
      double radius = innerRadius;
      double x = center.dx + radius * cos(angle) + 2000;
      double y = center.dy + radius * sin(angle) + 2000;
      positions.add(ValueNotifier<Offset>(Offset(x, y)));
    }

    for (int i = 0; i < outerCount; i++) {
      double angle = random.nextDouble() * 2 * pi;
      double radius = outerRadius;
      double x = center.dx + radius * cos(angle) + 2000;
      double y = center.dy + radius * sin(angle) + 2000;
      positions.add(ValueNotifier<Offset>(Offset(x, y)));
    }

    return positions;
  }

  static List<ValueNotifier<Offset>> generateTwoColumnPositions(
      int count, Rect area) {
    final double columnWidth = area.width / 2;
    const double padding = 100.0;
    final double columnHeight = area.height;

    List<ValueNotifier<Offset>> positions = [];

    int columnCount = (count / 2).ceil();
    int halfCount = count - columnCount;

    for (int i = 0; i < columnCount; i++) {
      double x = area.left + columnWidth / 2 - padding + 1000;
      double y = area.top + i * (columnHeight / columnCount) + 1000;
      positions.add(ValueNotifier<Offset>(Offset(x, y)));
    }

    for (int i = 0; i < halfCount; i++) {
      double x = area.left + columnWidth + padding + 1000;
      double y = area.top + i * (columnHeight / halfCount) + 1000;
      positions.add(ValueNotifier<Offset>(Offset(x, y)));
    }

    return positions;
  }
}
