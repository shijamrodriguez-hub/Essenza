import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../services/database_service.dart';

class UserSummaryScreen extends StatelessWidget {
  const UserSummaryScreen({super.key});

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
          'Resumen General de Fincas y Cultivos',
          style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ValueListenableBuilder(
            valueListenable: DatabaseService.farms.listenable(),
            builder: (context, farmsBox, _) {
              if (farmsBox.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay fincas registradas todavía.\nCrea una finca y sus lotes/cultivos para verlos aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                );
              }

              return ListView.builder(
                itemCount: farmsBox.length,
                itemBuilder: (context, farmIndex) {
                  final farm = farmsBox.getAt(farmIndex);
                  final farmName = farm is Map ? (farm['name'] ?? 'Sin nombre') : 'Finca';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CABECERA DE LA FINCA
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.agriculture_rounded, color: Color(0xFF2E7D32), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                farmName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4332),
                                ),
                              ),
                            ),
                            const Chip(
                              label: Text('Finca', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32))),
                              backgroundColor: Color(0xFFF4F7F2),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 1),

                        // LOTES ASOCIADOS A ESTA FINCA
                        ValueListenableBuilder(
                          valueListenable: DatabaseService.lots.listenable(),
                          builder: (context, lotsBox, _) {
                            // Filtramos los lotes que pertenecen a esta finca
                            final lotesDeEstaFinca = [];
                            for (var key in lotsBox.keys) {
                              final lot = lotsBox.get(key);
                              if (lot is Map && lot['farm'] == farmName) {
                                lotesDeEstaFinca.add(lot);
                              }
                            }

                            if (lotesDeEstaFinca.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(left: 10, bottom: 8),
                                child: Text(
                                  '• Sin lotes registrados en esta finca.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              );
                            }

                            return Column(
                              children: lotesDeEstaFinca.map((lote) {
                                final loteName = lote['name'] ?? 'Lote';
                                final area = lote['area'] ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10, left: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7FAF5),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.grass_rounded, size: 16, color: Color(0xFF2E7D32)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Lote: $loteName',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1B4332),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (area.isNotEmpty)
                                            Text(
                                              'Área: $area',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Aquí puedes anidar o listar los cultivos de este lote específico
                                      const Padding(
                                        padding: EdgeInsets.only(left: 24),
                                        child: Text(
                                          'Cultivo: Café / 500 plantas (2 años)', // Puedes enlazar tu caja de cultivos aquí de la misma forma
                                          style: TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}