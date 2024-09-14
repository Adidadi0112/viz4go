import 'package:flutter/material.dart';
import '../models/Node.dart';

class NodeWidget extends StatelessWidget {
  final MapEntry<String, int> entry;
  final List<ValueNotifier<Offset>> positions;
  final Node nodeData;

  const NodeWidget({super.key, required this.entry, required this.positions, required this.nodeData});

  @override
  Widget build(BuildContext context) {

    const width = 125.0;  // Zwiększenie szerokości dla lepszej przejrzystości
    const height = 80.0;  // Zwiększenie wysokości dla więcej treści

    // Ustawienie koloru w zależności od namespace
    Color getNodeColor() {
      switch (nodeData.namespace) {
        case 'cellular_component':
          return Colors.blueAccent.withOpacity(0.8);
        case 'biological_process':
          return Colors.greenAccent.withOpacity(0.8);
        case 'molecular_function':
          return Colors.orangeAccent.withOpacity(0.8);
        default:
          return Colors.grey.withOpacity(0.8); // domyślny kolor
      }
    }

    return Draggable(
      feedback: Container(
      ),
      childWhenDragging: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
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
          mainAxisAlignment: MainAxisAlignment.center,
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
        height: height,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 4),
            Text(
              entry.key,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
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
