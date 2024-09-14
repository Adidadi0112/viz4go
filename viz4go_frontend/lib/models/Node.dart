class Node {
  final String id;
  final String name;
  final String? definition;
  final String? namespace;
  final String? isA;
  final String? relationship;

  Node({
    required this.id,
    required this.name,
    this.definition,
    this.namespace,
    this.isA, 
    this.relationship,
  });

  // Factory method to create a Node from JSON
  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      definition: json['def'] as String?,  
      namespace: json['namespace'] as String?,
      isA: json['is_a'] as String?,
      relationship: json['relationship'] as String?,
    );
  }

  // Method to convert a GoTerm to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'def': definition,
      'namespace': namespace,
      'is_a': isA,
      'relationship': relationship,
    };
  }
}
