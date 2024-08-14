import 'package:flutter/material.dart';

class NodeWidget extends StatelessWidget {
  final MapEntry<String, int> entry;
  final List<ValueNotifier<Offset>> positions;

  const NodeWidget({super.key, required this.entry, required this.positions});

  @override
  Widget build(BuildContext context) {

    const width = 80.0; 
    const height = 50.0; 

    return Draggable(
      feedback: Container(
      ),
      childWhenDragging: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 237, 224, 219).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              entry.key,
              style: const TextStyle(fontSize: 10, color: Colors.black),
            ),
            const Text('name'),
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
          color: const Color.fromARGB(255, 255, 225, 212),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              entry.key,
              style: const TextStyle(fontSize: 10, color: Colors.black),
            ),
            const Text('name'),
          ],
        ),
      ),
    );
  }
}
