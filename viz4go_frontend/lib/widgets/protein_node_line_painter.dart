import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProteinNodeLinePainter extends CustomPainter {
  final List<ValueNotifier<Offset>> positions;
  final List<dynamic> connections; // [parent, child, …]
  final Map<String, int> nodeIndex;

  ProteinNodeLinePainter(this.positions, this.connections, this.nodeIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke
      ..color = Colors.white;

    const startFix = Offset(20, 0);
    const endFix = Offset(20, 10);

    for (final c in connections) {
      final int sIdx = nodeIndex[c[0]]!;
      final int eIdx = nodeIndex[c[1]]!;

      final Offset start = positions[sIdx].value + startFix; // ↖ tu będzie grot
      final Offset end = positions[eIdx].value + endFix;

      canvas.drawLine(start, end, paint);
      _drawArrow(canvas, paint, start,
          end); // grot przy 'start', skierowany w stronę 'end'
    }
  }

  /// Rysuje grot o wierzchołku w `tip`, zwrócony w stronę `tail`.
  void _drawArrow(Canvas canvas, Paint paint, Offset tip, Offset tail) {
    const double len = 6.0;
    const double angle = 30 * math.pi / 180;

    // ↓↓ JEDYNA ZMIANA ↓↓ – odwracamy wektor, by grot patrzył do 'tail'
    final double dir = (tail - tip).direction;

    final Offset p1 = tip + Offset.fromDirection(dir + angle, len);
    final Offset p2 = tip + Offset.fromDirection(dir - angle, len);

    final Path path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
