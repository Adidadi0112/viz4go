import 'package:flutter/material.dart';

class LinePainter extends CustomPainter {
  final List<ValueNotifier<Offset>> positions;
  final List<dynamic>  connections;
  final Map<String, int> nodeIndex;

  LinePainter(this.positions, this.connections, this.nodeIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
    

    for (var connection in connections) {
      int startIndex = nodeIndex[connection[0]]!;
      int endIndex = nodeIndex[connection[1]]!;

      paint.color = _getColorForRelations(connection[2]);
      final start = positions[startIndex].value + const Offset(40, 25);
      final end = positions[endIndex].value + const Offset(40, 25);

      canvas.drawLine(start, end, paint); 
    }
  }

  Color _getColorForRelations(String relation) {
    switch (relation) {
      case 'is_a':
        return Colors.black.withOpacity(0.3);
      case 'part_of':
        return Colors.blue.withOpacity(0.3);
      case "negatively_regulates":
        return Colors.red.withOpacity(0.3);
      case "regulates":
        return Colors.orange.withOpacity(0.3);
      default:
        return Colors.black.withOpacity(0.3);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}