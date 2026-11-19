class SyncService {
  static bool isOnline = true;

  static Future<void> synchronize() async {
    if (!isOnline) {
      return;
    }

    // Aquí posteriormente conectaremos
    // la base de datos local con el servidor.

    await Future.delayed(
      const Duration(seconds: 1),
    );
  }
}