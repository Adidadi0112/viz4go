import 'package:flutter/material.dart';
import '../models/node.dart';

class NodeWidget extends StatelessWidget {
  final MapEntry<String, int> entry;
  final List<ValueNotifier<Offset>> positions;
  final Node nodeData;
  bool isVisible = true;
  bool isSmall = false;

  NodeWidget(
      {super.key,
      required this.entry,
      required this.positions,
      required this.nodeData,
      this.isVisible = true,
      this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final width = !isSmall ? 135.0 : 45.0;

    Color getNodeColor() {
      switch (nodeData.namespace) {
        case 'cellular_component':
          return isVisible
              ? Colors.blueAccent.withValues(alpha: 0.8)
              : Colors.blueAccent.withValues(alpha: 0.2);
        case 'biological_process':
          return isVisible
              ? Colors.greenAccent.withValues(alpha: 0.8)
              : Colors.greenAccent.withValues(alpha: 0.2);
        case 'molecular_function':
          return isVisible
              ? Colors.orangeAccent.withValues(alpha: 0.8)
              : Colors.orangeAccent.withValues(alpha: 0.2);
        default:
          return Colors.grey.withValues(alpha: 0.8);
      }
    }

    return Draggable(
      feedback: Container(),
      childWhenDragging: Container(
        width: width,
        padding: EdgeInsets.all(isSmall ? 1 : 4),
        decoration: BoxDecoration(
          color: getNodeColor().withValues(alpha: 0.5),
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
              style:
                  TextStyle(fontSize: !isSmall ? 12 : 4, color: Colors.black),
            ),
            //!isSmall ?
            Text(
              nodeData.name,
              style:
                  TextStyle(fontSize: !isSmall ? 12 : 4, color: Colors.black54),
              textAlign: TextAlign.center,
            )
            // : Container(),
          ],
        ),
      ),
      onDragUpdate: (details) {
        positions[entry.value].value += details.delta;
      },
      child: Container(
        width: width,
        padding: EdgeInsets.all(isSmall ? 1 : 4),
        decoration: BoxDecoration(
          color: getNodeColor(),
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
              style: TextStyle(
                  fontSize: !isSmall ? 12 : 4,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            //  !isSmall ?
            Text(
              nodeData.name,
              style:
                  TextStyle(fontSize: !isSmall ? 12 : 4, color: Colors.white70),
              textAlign: TextAlign.center,
            )
            //      : Container(),
          ],
        ),
      ),
    );
  }
}
