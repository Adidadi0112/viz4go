import 'package:flutter/material.dart';

class LinePainter extends CustomPainter {
  final List<ValueNotifier<Offset>> positions;
  final List<dynamic> connections;
  final Map<String, int> nodeIndex;
  final List<String> activeFilters; // Dodanie filtrów

  LinePainter(this.positions, this.connections, this.nodeIndex, this.activeFilters);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var connection in connections) {
      if (activeFilters.contains(connection[2])) { // Filtracja
        int startIndex = nodeIndex[connection[0]]!;
        int endIndex = nodeIndex[connection[1]]!;

        paint.color = _getColorForRelations(connection[2]);
        final start = positions[startIndex].value + const Offset(40, 25);
        final end = positions[endIndex].value + const Offset(40, 25);

        canvas.drawLine(start, end, paint);
      }
    }
  }

  Color _getColorForRelations(String relation) {
    switch (relation) {
      case 'is_a':
        return Color(0xFFFFFFFF);
      case 'part_of':
        return Color(0xFF00BCD4);
      case "negatively_regulates":
        return Color(0xFFE91E63);
      case "regulates":
        return Color(0xFFCDDC39);
      default:
        return Colors.black.withOpacity(0.3);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
