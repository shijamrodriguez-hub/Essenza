import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class AlertsScreen extends StatefulWidget {
  final double currentHumidity;
  final bool isIrrigating;

  const AlertsScreen({
    super.key,
    this.currentHumidity = 0.0,
    this.isIrrigating = false,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<dynamic> _alertsList = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final box = Hive.isBoxOpen('alerts') ? Hive.box('alerts') : await Hive.openBox('alerts');
    setState(() {
      _alertsList = box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> _clearAlerts() async {
    final box = Hive.isBoxOpen('alerts') ? Hive.box('alerts') : await Hive.openBox('alerts');
    await box.clear();
    _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B4332)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Centro de Alertas IoT',
          style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_alertsList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFF1B4332)),
              tooltip: 'Limpiar alertas',
              onPressed: _clearAlerts,
            ),
        ],
      ),
      body: SafeArea(
        child: _alertsList.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No hay alertas registradas aún.\nLas notificaciones del sensor aparecerán aquí con su hora exacta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _alertsList.length,
                itemBuilder: (context, index) {
                  final alert = _alertsList[index] as Map;
                  final type = alert['type'] ?? 'info';
                  final Color color = type == 'warning'
                      ? const Color(0xFFE63946)
                      : (type == 'success' ? const Color(0xFF2E7D32) : const Color(0xFFFB8C00));
                  final IconData icon = type == 'warning'
                      ? Icons.warning_amber_rounded
                      : (type == 'success' ? Icons.check_circle_outline_rounded : Icons.notifications_active_rounded);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withOpacity(0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      (alert['title'] ?? 'Alerta de Riego').toString(),
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      (alert['time'] ?? '').toString(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B4332),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (alert['message'] ?? '').toString(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568), height: 1.35),
                              ),
                              if (alert['finca'] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Zona: ${alert['finca']} • ${alert['lote']} (${alert['crop']})',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}