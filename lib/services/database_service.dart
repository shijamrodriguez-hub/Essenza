import 'package:hive_ce/hive.dart';

class DatabaseService {
  static Future<void> init() async {}

  static Box get users => Hive.box('users');
  static Box get farms => Hive.box('farms');
  static Box get lots => Hive.box('lots');
  static Box get crops => Hive.box('crops'); // <-- Agregado para cultivos
  static Box get history => Hive.box('history');
  static Box get alerts => Hive.box('alerts');

  // Guardar una nueva finca
  static Future<void> addFarm(Map<String, dynamic> farmData) async {
    await farms.add(farmData);
  }

  // Obtener todas las fincas guardadas
  static List getFarms() {
    return farms.values.toList();
  }

  // Eliminar una finca por su índice o clave
  static Future<void> deleteFarm(int index) async {
    await farms.deleteAt(index);
  }
}