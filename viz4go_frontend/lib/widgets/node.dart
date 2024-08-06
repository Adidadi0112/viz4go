import 'package:flutter/material.dart';

class NodeWidget extends StatelessWidget {
  final String id;

  const NodeWidget({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return InkWell(
    onTap: () {
      print('clicked');
    },
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color.fromARGB(255, 237, 224, 219), spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Text(id),
          const Text('name'),
          ],
      ),
    ),
  );
  }
}