import 'package:flutter/material.dart';
import '../models/node.dart';

class NodeWidget extends StatelessWidget {
  final MapEntry<String, int> entry;
  final List<ValueNotifier<Offset>> positions;
  final Node nodeData;
  bool isVisible = true;

  NodeWidget(
      {super.key,
      required this.entry,
      required this.positions,
      required this.nodeData,
      this.isVisible = true});

  @override
  Widget build(BuildContext context) {
    const width = 135.0; // Zwiększenie szerokości dla lepszej przejrzystości

    // Ustawienie koloru w zależności od namespace
    Color getNodeColor() {
      switch (nodeData.namespace) {
        case 'cellular_component':
          return isVisible
              ? Colors.blueAccent.withOpacity(0.8)
              : Colors.blueAccent.withOpacity(0.2);
        case 'biological_process':
          return isVisible
              ? Colors.greenAccent.withOpacity(0.8)
              : Colors.greenAccent.withOpacity(0.2);
        case 'molecular_function':
          return isVisible
              ? Colors.orangeAccent.withOpacity(0.8)
              : Colors.orangeAccent.withOpacity(0.2);
        default:
          return Colors.grey.withOpacity(0.8); // domyślny kolor
      }
    }

    return Draggable(
      feedback: Container(),
      childWhenDragging: Container(
        width: width,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: getNodeColor().withOpacity(0.5), // Kolor podczas przeciągania
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              entry.key,
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
            Text(
              nodeData.name,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      onDragUpdate: (details) {
        positions[entry.value].value += details.delta;
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: getNodeColor(), // Kolor zależny od namespace
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Text(
              entry.key,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              nodeData.name,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
