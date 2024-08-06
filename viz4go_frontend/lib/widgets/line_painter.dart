import 'package:flutter/material.dart';

class LinePainter extends CustomPainter {
  final List<ValueNotifier<Offset>> positions;
  final List<List<dynamic>>  connections;
  static const double nodeSize = 50.0;

  LinePainter(this.positions, this.connections)
      : super(repaint: Listenable.merge(positions));

  @override
  void paint(Canvas canvas, Size size) {
    final paintIsA = Paint()
    ..color = Colors.black
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

    final paintPartOf = Paint()
    ..color = Colors.black
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;


    for (int i = 0; i < connections[0].length; i++) {  
      final start = positions[i].value + Offset(nodeSize / 2, nodeSize / 2);
      final end = positions[i + 1].value + Offset(nodeSize / 2, nodeSize / 2);
      final paint = connections[0][i][2] == 'is_a' ? paintIsA : paintPartOf;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}