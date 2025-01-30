import 'node.dart';

class ProteinNode extends Node {
  bool isExpanded;
  List<dynamic> childGoTerms;

  ProteinNode({
    required super.id,
    required super.name,
    this.isExpanded = false,
    this.childGoTerms = const [],
  }) : super(
          definition: null,
          namespace: null,
          isA: null,
          relationship: null,
        );
}
