class FincaModel {
  final String id;
  final String userId;
  final String name;
  final String location;
  final String description;

  FincaModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.location,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'location': location,
      'description': description,
    };
  }

  factory FincaModel.fromMap(Map<String, dynamic> map) {
    return FincaModel(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      location: map['location'],
      description: map['description'],
    );
  }
}