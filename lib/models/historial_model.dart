class HistorialModel {
  final String id;
  final String loteId;
  final String userId;
  final String type;
  final String description;
  final DateTime date;

  HistorialModel({
    required this.id,
    required this.loteId,
    required this.userId,
    required this.type,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loteId': loteId,
      'userId': userId,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory HistorialModel.fromMap(Map<String, dynamic> map) {
    return HistorialModel(
      id: map['id'],
      loteId: map['loteId'],
      userId: map['userId'],
      type: map['type'],
      description: map['description'],
      date: DateTime.parse(map['date']),
    );
  }
}