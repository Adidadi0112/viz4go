import 'dart:math';
import 'package:flutter/material.dart';

class PositionGenerator {
  static List<ValueNotifier<Offset>> generateTreePositions(
      Map<String, int> nodeIndex, List<dynamic> items, Rect area) {
    // Wygenerowanie poziomów wierzchołków przy użyciu metody groupGOLevels
    final List<dynamic> levels = groupGOLevels(items);
    print(levels);

    List<ValueNotifier<Offset>> positions = List.generate(
        nodeIndex.length, (_) => ValueNotifier<Offset>(Offset.zero));
    const double nodeWidth = 1000.0;
    const double nodeHeight = 80.0;
    const double verticalSpacing = 60.0;

    // Ustawienie pozycji wierzchołków na odpowiednich poziomach
    double y = area.top + 2000;
    for (int i = levels.length - 1; i >= 0; i--) {
      final level = levels[i];
      final double horizontalSpacing =
          (area.width - level.length * nodeWidth) / (level.length + 1);
      double x = area.left + horizontalSpacing + 2000;
      for (int j = 0; j < level.length; j++) {
        final term = level[j];
        final index = nodeIndex[term]!;
        positions[index].value = Offset(x, y);
        x += nodeWidth + horizontalSpacing;
      }

      y += nodeHeight + verticalSpacing;
    }

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

  // Metoda pomocnicza do grupowania wierzchołków na poziomy
  static List<List<String>> groupGOLevels(List<dynamic> data) {
    final Map<String, List<String>> tree = {};

    // Budowanie drzewa
    for (var relation in data) {
      final parent = relation[0];
      final child = relation[1];

      if (!tree.containsKey(parent)) {
        tree[parent] = [];
      }
      tree[parent]!.add(child);
    }

    // Znalezienie korzeni drzewa
    Set<String> allChildren = {};
    for (var children in tree.values) {
      allChildren.addAll(children);
    }
    print(tree);
    print(allChildren);

    List<String> roots =
        tree.keys.where((term) => !allChildren.contains(term)).toList();
    print(roots);

    // Grupowanie wierzchołków w poziomy
    List<List<String>> levels = [];
    for (var root in roots) {
      _addToLevels(tree, root, levels, 0);
    }

    return levels;
  }

  // Rekurencyjna metoda pomocnicza do dodawania wierzchołków na odpowiednie poziomy
  static void _addToLevels(Map<String, List<String>> tree, String term,
      List<List<String>> levels, int depth) {
    while (levels.length <= depth) {
      levels.add([]);
    }

    if (!levels[depth].contains(term)) {
      levels[depth].add(term);
    }

    if (tree.containsKey(term)) {
      for (var child in tree[term]!) {
        _addToLevels(tree, child, levels, depth + 1);
      }
    }

    // Usuwanie duplikatów z poziomu wyższego, które są obecne na niższych poziomach
    if (depth + 1 < levels.length) {
      levels[depth] = levels[depth]
          .where((t) => !levels.sublist(depth + 1).expand((x) => x).contains(t))
          .toList();
    }
  }
}
