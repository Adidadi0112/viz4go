import 'package:flutter/material.dart';

import '../home_screen.dart';

class LinePainter extends CustomPainter {
  final List<ValueNotifier<Offset>> positions;
  final List<dynamic> connections;
  final Map<String, int> nodeIndex;
  final List<String> activeFilters;
  final LayoutMode currentLayoutMode;

  LinePainter(this.positions, this.connections, this.nodeIndex,
      this.activeFilters, this.currentLayoutMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    Offset startFix = currentLayoutMode == LayoutMode.tree
        ? const Offset(60, 0)
        : const Offset(70, 25);
    Offset endFix = currentLayoutMode == LayoutMode.tree
        ? const Offset(60, 50)
        : const Offset(70, 25);

    for (var connection in connections) {
      if (activeFilters.contains(connection[2])) {
        // Filtracja
        int startIndex = nodeIndex[connection[0]]!;
        int endIndex = nodeIndex[connection[1]]!;

        paint.color = _getColorForRelations(connection[2]);

        final start = positions[startIndex].value + startFix;
        final end = positions[endIndex].value + endFix;

        canvas.drawLine(start, end, paint);
        if (currentLayoutMode == LayoutMode.tree) {
          _drawArrowHead(canvas, paint, end, start);
        }
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Paint paint, Offset start, Offset end) {
    const arrowAngle = 30 * 3.14159265 / 180; 
    const arrowLength = 10.0; 

    final direction = (start - end).direction;

    final arrowPoint1 =
        end + Offset.fromDirection(direction + arrowAngle, arrowLength);
    final arrowPoint2 =
        end + Offset.fromDirection(direction - arrowAngle, arrowLength);

    final path = Path()
      ..moveTo(end.dx, end.dy) 
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy) 
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close(); 

    final arrowPaint = Paint()
      ..color = paint.color 
      ..style = PaintingStyle.fill; 

    canvas.drawPath(path, arrowPaint);
  }

  Color _getColorForRelations(String relation) {
    switch (relation) {
      case 'is_a':
        return const Color(0xFFFFFFFF);
      case 'part_of':
        return const Color.fromARGB(255, 127, 240, 255);
      case "negatively_regulates":
        return const Color(0xFFE91E63);
      case "regulates":
        return const Color(0xFFCDDC39);
      default:
        return Colors.black.withValues(alpha: 0.3);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
