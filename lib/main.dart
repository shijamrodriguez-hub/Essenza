import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'models/user_model.dart'; // Importante para crear el usuario por defecto

Future<void> main() async {
  // 1. Asegurar la inicialización de los widgets de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializar Hive CE para Flutter
  await Hive.initFlutter();

  // 3. Abrir las cajas (boxes) de la base de datos que tu aplicación utiliza
  await Hive.openBox('users');
  await Hive.openBox('farms');
  await Hive.openBox('lots');
  await Hive.openBox('history');
  await Hive.openBox('alerts');
  await Hive.openBox('crops');

  // 4. Inicializar tu servicio de base de datos
  await DatabaseService.init();

  // 5. INYECTAR ADMINISTRADOR POR DEFECTO SI LA CAJA DE USUARIOS ESTÁ VACÍA (Usando el correo como llave)
  final userBox = DatabaseService.users;
  if (userBox.isEmpty) {
    final adminUser = UserModel(
      id: 'admin_default',
      name: 'Administrador General',
      email: 'admin@essenza.com',
      password: 'adminPassword123',
      role: 'admin',
    );
    await userBox.put('admin@essenza.com', adminUser.toMap());
  }

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const EssenzaApp(),
    ),
  );
}

class EssenzaApp extends StatelessWidget {
  const EssenzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ESSENZA',
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAF5),
      ),
      home: const SplashScreen(),
    );
  }
}