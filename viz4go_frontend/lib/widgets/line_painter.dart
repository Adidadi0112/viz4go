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

        // Współrzędne początkowe i końcowe linii
        final start = positions[startIndex].value + startFix;
        final end = positions[endIndex].value + endFix;

        // Rysowanie linii
        canvas.drawLine(start, end, paint);
        if (currentLayoutMode == LayoutMode.tree) {
          _drawArrowHead(canvas, paint, end, start);
        }
      }
    }
  }

  // Funkcja do rysowania wypełnionego grota strzałki na końcu linii
  void _drawArrowHead(Canvas canvas, Paint paint, Offset start, Offset end) {
    // Kierunek linii
    const arrowAngle = 30 * 3.14159265 / 180; // 30 stopni w radianach
    const arrowLength = 10.0; // Długość grota strzałki

    // Obliczenie wektora kierunkowego linii (z `end` w stronę `start`)
    final direction = (start - end).direction;

    // Obliczenie dwóch punktów grota strzałki po bokach linii
    final arrowPoint1 =
        end + Offset.fromDirection(direction + arrowAngle, arrowLength);
    final arrowPoint2 =
        end + Offset.fromDirection(direction - arrowAngle, arrowLength);

    // Tworzenie trójkąta jako grot strzałki
    final path = Path()
      ..moveTo(end.dx, end.dy) // Punkt końcowy linii (koniec strzałki)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy) // Pierwszy bok grota strzałki
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy) // Drugi bok grota strzałki
      ..close(); // Zamknięcie ścieżki, tworząc trójkąt

    // Zmiana stylu na wypełnienie i rysowanie wypełnionej strzałki
    final arrowPaint = Paint()
      ..color = paint.color // Kolor grota taki sam jak linia
      ..style = PaintingStyle.fill; // Wypełnienie

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
        return Colors.black.withOpacity(0.3);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
