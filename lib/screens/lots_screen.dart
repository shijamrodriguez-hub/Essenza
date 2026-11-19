import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../services/database_service.dart';

class LotsScreen extends StatefulWidget {
  const LotsScreen({super.key});

  @override
  State<LotsScreen> createState() => _LotsScreenState();
}

class _LotsScreenState extends State<LotsScreen> {
  void _showAddLotDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController areaController = TextEditingController();
    
    // Obtenemos las fincas registradas en Hive para que el usuario pueda seleccionarlas
    final farmsBox = DatabaseService.farms;
    List<String> farmNames = [];
    
    for (var key in farmsBox.keys) {
      final farm = farmsBox.get(key);
      if (farm is Map && farm.containsKey('name')) {
        farmNames.add(farm['name'].toString());
      }
    }

    // Si no hay fincas creadas todavía, ponemos una por defecto
    if (farmNames.isEmpty) {
      farmNames.add('Finca Principal');
    }

    String selectedFarmForLot = farmNames.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Nuevo Lote',
                style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Desplegable para seleccionar la Finca a la que pertenece
                    const Text(
                      '¿A qué Finca pertenece?',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedFarmForLot,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF7FAF5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: farmNames.map((farm) {
                        return DropdownMenuItem(
                          value: farm,
                          child: Text(farm, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedFarmForLot = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Lote (Ej. Lote Norte)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: areaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Área o Hectáreas (Ej. 2.5 Ha)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      // Guardar en la caja de Hive de lotes
                      await DatabaseService.lots.add({
                        'name': nameController.text.trim(),
                        'farm': selectedFarmForLot,
                        'area': areaController.text.isEmpty ? 'No especificada' : areaController.text.trim(),
                        'createdAt': DateTime.now().toIso8601String(),
                      });

                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
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
          'Gestión de Lotes',
          style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lotes Registrados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddLotDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Añadir Lote', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Listado en tiempo real utilizando Hive y ValueListenableBuilder
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: DatabaseService.lots.listenable(),
                  builder: (context, box, _) {
                    if (box.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay lotes registrados todavía.\n¡Haz clic en "Añadir Lote" para comenzar!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: box.length,
                      itemBuilder: (context, index) {
                        final lot = box.getAt(index);
                        final lotName = lot is Map ? (lot['name'] ?? 'Sin nombre') : 'Lote';
                        final farmName = lot is Map ? (lot['farm'] ?? 'Sin finca') : '';
                        final area = lot is Map ? (lot['area'] ?? '') : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.grass_rounded, color: Color(0xFF2E7D32), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lotName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.agriculture_rounded, size: 14, color: Color(0xFF2E7D32)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Finca: $farmName',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    if (area.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Área: $area',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () {
                                  // Eliminar lote de Hive de forma local
                                  box.deleteAt(index);
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
            ],
          ),
        ),
      ),
    );
  }
}