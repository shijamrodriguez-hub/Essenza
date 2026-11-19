import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../models/user_model.dart';
import 'session_service.dart';

class AuthService {
  // Asegurar que la caja 'users' esté abierta de forma segura
  static Future<Box> _getUsersBox() async {
    if (Hive.isBoxOpen('users')) {
      return Hive.box('users');
    }
    return await Hive.openBox('users');
  }

  // ============================================================
  // REGISTRAR USUARIO (Guarda permanentemente en Hive)
  // ============================================================
  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? linkedProducerCode,
  }) async {
    final usersBox = await _getUsersBox();
    final normalizedEmail = email.trim().toLowerCase();

    // Validar si el correo ya existe
    if (usersBox.containsKey(normalizedEmail)) {
      return false; 
    }

    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final farmCode = role == 'productor' ? 'ESC-${userId.substring(userId.length - 6)}' : null;

    final Map<String, dynamic> userMap = {
      'id': userId,
      'name': name.trim(),
      'email': normalizedEmail,
      'password': password,
      'role': role,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (role == 'productor') {
      userMap['farmCode'] = farmCode;
    }
    if (role == 'consulta') {
      userMap['linkedProducerCode'] = linkedProducerCode?.trim();
    }

    // 1. Guardar en la caja de Hive y forzar escritura física en disco
    await usersBox.put(normalizedEmail, userMap);
    await usersBox.flush();

    // 2. Guardar la sesión activa asegurando el ID y el rol
    await SessionService.saveSession(
      userId: userId,
      role: role,
    );

    return true;
  }

  // ============================================================
  // INICIAR SESIÓN (Validación segura)
  // ============================================================
  static Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final usersBox = await _getUsersBox();
    final normalizedEmail = email.trim().toLowerCase();

    // Búsqueda directa por llave (correo normalizado)
    if (usersBox.containsKey(normalizedEmail)) {
      final item = usersBox.get(normalizedEmail);
      if (item != null) {
        final map = Map<dynamic, dynamic>.from(item);
        if (map['password']?.toString() == password) {
          await SessionService.saveSession(
            userId: map['id'].toString(),
            role: map['role'].toString(),
          );
          return UserModel.fromMap(map);
        }
      }
    }

    // Búsqueda secundaria iterando sobre las llaves por seguridad
    for (final key in usersBox.keys) {
      final item = usersBox.get(key);
      if (item != null) {
        final map = Map<dynamic, dynamic>.from(item);
        final userEmail = map['email']?.toString().toLowerCase();
        final userPassword = map['password']?.toString();

        if (userEmail == normalizedEmail && userPassword == password) {
          await SessionService.saveSession(
            userId: map['id'].toString(),
            role: map['role'].toString(),
          );
          return UserModel.fromMap(map);
        }
      }
    }

    return null;
  }

  // ============================================================
  // OBTENER USUARIO ACTUAL
  // ============================================================
  static Future<UserModel?> getCurrentUser() async {
    final userId = await SessionService.getUserId();
    if (userId == null) return null;

    final usersBox = await _getUsersBox();
    for (final key in usersBox.keys) {
      final item = usersBox.get(key);
      if (item != null) {
        final map = Map<dynamic, dynamic>.from(item);
        if (map['id']?.toString() == userId) {
          return UserModel.fromMap(map);
        }
      }
    }
    return null;
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================
  static Future<void> logout() async {
    await SessionService.logout();
  }
}