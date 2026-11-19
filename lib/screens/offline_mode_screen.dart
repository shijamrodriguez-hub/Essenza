import 'package:flutter/material.dart';

class OfflineModeScreen extends StatelessWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Modo Finca',
          style: TextStyle(
            color: Color(0xFF165631),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3E8),
                borderRadius:
                    BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 50,
                    color: Color(0xFF2E7D32),
                  ),

                  SizedBox(height: 15),

                  Text(
                    'Modo sin conexión',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF165631),
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Puedes continuar trabajando con la información disponible en tu dispositivo.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _option(
              Icons.home_work_outlined,
              'Consultar fincas',
            ),

            _option(
              Icons.grass_outlined,
              'Consultar lotes',
            ),

            _option(
              Icons.history,
              'Consultar historial',
            ),

            _option(
              Icons.note_alt_outlined,
              'Registrar observaciones',
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.sync,
                ),
                label: const Text(
                  'Sincronizar información',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF165631),
                  foregroundColor: Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    IconData icon,
    String title,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF2E7D32),
          ),

          const SizedBox(width: 15),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}s