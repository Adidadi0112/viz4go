import 'node.dart';

class ProteinNode extends Node {
  bool isExpanded;
  List<List<String>> levels;

  ProteinNode({
    required super.id,
    required super.name,
    this.isExpanded = false,
    this.levels = const [],
  }) : super(
          definition: null,
          namespace: null,
          isA: null,
          relationship: null,
        );
}
