// lib/models/data_model.dart

class DataModel {
  final int id;
  final String name;
  final String namespace;
  final String def;
  final String isA;
  final String relationship;

  DataModel({
    required this.id,
    required this.name,
    required this.namespace,
    required this.def,
    required this.isA,
    required this.relationship,
  });

  // Tworzenie obiektu DataModel z mapy (z bazy danych)
  factory DataModel.fromMap(Map<String, dynamic> json) => new DataModel(
        id: json['id'],
        name: json['name'],
        namespace: json['namespace'],
        def: json['def'],
        isA: json['is_a'],
        relationship: json['relationship'],
      );

  // Konwersja obiektu DataModel do mapy (do zapisu w bazie danych)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'namespace': namespace,
      'def': def,
      'is_a': isA,
      'relationship': relationship,
    };
  }
}
