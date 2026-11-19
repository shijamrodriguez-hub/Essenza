import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B4332)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Panel General - Base de Datos',
            style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
              tooltip: 'Descargar Reporte General PDF',
              onPressed: () async {
                await PdfService.generateAndDownloadPdf(
                  loteName: 'Panel Consolidado Global',
                  crop: 'Todas las Fincas y Propietarios',
                );
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2E7D32),
            tabs: [
              Tab(icon: Icon(Icons.people_rounded), text: 'Usuarios y Roles'),
              Tab(icon: Icon(Icons.agriculture_rounded), text: 'Fincas y Dueños'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Historial'),
              Tab(icon: Icon(Icons.notifications_rounded), text: 'Alertas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            _buildFarmsAndOwnersTab(),
            _buildHistoryTab(),
            _buildAlertsTab(),
          ],
        ),
      ),
    );
  }

  // TAB 1: USUARIOS
  Widget _buildUsersTab() {
    return ValueListenableBuilder(
      valueListenable: DatabaseService.users.listenable(),
      builder: (context, box, _) {
        if (box.isEmpty) return const Center(child: Text('No hay usuarios registrados.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: box.length,
          itemBuilder: (context, index) {
            final user = box.getAt(index);
            final map = user is Map ? user : {};
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.person, color: Color(0xFF2E7D32)),
                ),
                title: Text(map['name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Correo: ${map['email']}\nRol: ${map['role']}${map['farmCode'] != null ? ' | Código: ${map['farmCode']}' : ''}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => box.deleteAt(index),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // TAB 2: FINCAS, DUEÑOS Y LOTES CONECTADOS
  Widget _buildFarmsAndOwnersTab() {
    return ValueListenableBuilder(
      valueListenable: DatabaseService.farms.listenable(),
      builder: (context, farmsBox, _) {
        if (farmsBox.isEmpty) {
          return const Center(child: Text('No hay fincas registradas en la base de datos.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: farmsBox.length,
          itemBuilder: (context, index) {
            final farm = farmsBox.getAt(index);
            final farmMap = farm is Map ? farm : {};
            final farmName = farmMap['name'] ?? 'Finca';
            final ownerEmail = farmMap['ownerEmail'] ?? farmMap['email'] ?? 'Productor general';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Finca: $farmName',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => farmsBox.deleteAt(index),
                        ),
                      ],
                    ),
                    Text(
                      'Propietario / Productor: $ownerEmail',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const Divider(height: 20),
                    
                    // Lotes y Cultivos asociados
                    ValueListenableBuilder(
                      valueListenable: DatabaseService.lots.listenable(),
                      builder: (context, lotsBox, _) {
                        final lotsList = [];
                        for (var key in lotsBox.keys) {
                          final lot = lotsBox.get(key);
                          if (lot is Map && lot['farm'] == farmName) {
                            lotsList.add(lot);
                          }
                        }

                        if (lotsList.isEmpty) {
                          return const Text('• Sin lotes asociados a esta finca.', style: TextStyle(color: Colors.grey, fontSize: 12));
                        }

                        return Column(
                          children: lotsList.map((lot) => Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Lote: ${lot['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('Área: ${lot['area'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          )).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // TAB 3: HISTORIAL
  Widget _buildHistoryTab() {
    return ValueListenableBuilder(
      valueListenable: DatabaseService.history.listenable(),
      builder: (context, box, _) {
        if (box.isEmpty) return const Center(child: Text('No hay registros de historial.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: box.length,
          itemBuilder: (context, index) {
            final item = box.getAt(index);
            final map = item is Map ? item : {};
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(map['activity'] ?? 'Actividad', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${map['detail'] ?? ''}\nFecha: ${map['date'] ?? ''}'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  // TAB 4: ALERTAS
  Widget _buildAlertsTab() {
    return ValueListenableBuilder(
      valueListenable: DatabaseService.alerts.listenable(),
      builder: (context, box, _) {
        if (box.isEmpty) return const Center(child: Text('No hay alertas en el sistema.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: box.length,
          itemBuilder: (context, index) {
            final alert = box.getAt(index);
            final map = alert is Map ? alert : {};
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                title: Text(map['title'] ?? 'Alerta', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(map['message'] ?? ''),
              ),
            );
          },
        );
      },
    );
  }
}