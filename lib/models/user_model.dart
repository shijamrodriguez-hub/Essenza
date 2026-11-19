class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role;
  final String? farmCode; // <--- El campo que faltaba por declarar
  final String? linkedProducerCode;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.farmCode,
    this.linkedProducerCode,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      farmCode: map['farmCode']?.toString(), // <--- Mapeo desde Hive
      linkedProducerCode: map['linkedProducerCode']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'farmCode': farmCode, // <--- Guardado hacia Hive
      'linkedProducerCode': linkedProducerCode,
    };
  }
}