import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String? _selectedFarmKey;
  String? _selectedLotKey;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _ageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Asegurar que las cajas de Hive estén abiertas
  Future<void> _openBoxes() async {
    if (!Hive.isBoxOpen('crops')) await Hive.openBox('crops');
    if (!Hive.isBoxOpen('farms')) await Hive.openBox('farms');
    if (!Hive.isBoxOpen('lots')) await Hive.openBox('lots');
  }

  void _showAddCropModal(BuildContext context) {
    _nameController.clear();
    _typeController.clear();
    _ageController.clear();
    _quantityController.clear();
    _selectedFarmKey = null;
    _selectedLotKey = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final farmsBox = Hive.box('farms');
            final lotsBox = Hive.box('lots');
            final farmsList = farmsBox.keys.toList();

            // Filtro inteligente y flexible para los lotes
            final filteredLots = lotsBox.keys.where((lotKey) {
              final lotData = lotsBox.get(lotKey);
              if (lotData is Map && _selectedFarmKey != null) {
                final selectedFarmData = farmsBox.get(_selectedFarmKey);
                final selectedFarmName = selectedFarmData is Map 
                    ? selectedFarmData['name']?.toString().trim().toLowerCase() 
                    : _selectedFarmKey.toString().trim().toLowerCase();
                
                final selectedFarmKeyStr = _selectedFarmKey.toString().trim().toLowerCase();

                final lotFarmKey = lotData['farmKey']?.toString().trim().toLowerCase();
                final lotFarm = lotData['farm']?.toString().trim().toLowerCase();
                final lotFarmName = lotData['farmName']?.toString().trim().toLowerCase();

                // Comprobar coincidencias por ID o por Nombre de Finca
                bool matches = (lotFarmKey != null && (lotFarmKey == selectedFarmKeyStr || lotFarmKey == selectedFarmName)) ||
                               (lotFarm != null && (lotFarm == selectedFarmKeyStr || lotFarm == selectedFarmName)) ||
                               (lotFarmName != null && (lotFarmName == selectedFarmKeyStr || lotFarmName == selectedFarmName));

                return matches;
              }
              return false;
            }).toList();

            // RESPALDO: Si por alguna razón el filtro estricto no encuentra lotes pero existen lotes creados, 
            // mostramos todos los lotes de la caja para evitar que aparezca vacío.
            final lotsList = filteredLots.isEmpty ? lotsBox.keys.toList() : filteredLots;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registrar Nuevo Cultivo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Desplegable de Fincas
                      DropdownButtonFormField<String>(
                        value: _selectedFarmKey,
                        decoration: InputDecoration(
                          labelText: 'Seleccionar Finca',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F8E9),
                        ),
                        items: farmsList.map((farmKey) {
                          final farmData = farmsBox.get(farmKey);
                          final farmName = farmData is Map
                              ? farmData['name'] ?? 'Sin nombre'
                              : farmKey.toString();
                          return DropdownMenuItem<String>(
                            value: farmKey.toString(),
                            child: Text(farmName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedFarmKey = value;
                            _selectedLotKey = null; // Reiniciar lote al cambiar finca
                          });
                        },
                        validator: (value) => value == null
                            ? 'Por favor selecciona una finca'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Desplegable de Lotes
                      DropdownButtonFormField<String>(
                        value: _selectedLotKey,
                        decoration: InputDecoration(
                          labelText: 'Seleccionar Lote',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F8E9),
                        ),
                        items: lotsList.map((lotKey) {
                          final lotData = lotsBox.get(lotKey);
                          final lotName = lotData is Map
                              ? lotData['name'] ?? 'Sin nombre'
                              : lotKey.toString();
                          return DropdownMenuItem<String>(
                            value: lotKey.toString(),
                            child: Text(lotName),
                          );
                        }).toList(),
                        onChanged: _selectedFarmKey == null
                            ? null
                            : (value) {
                                setModalState(() {
                                  _selectedLotKey = value;
                                });
                              },
                        validator: (value) => value == null
                            ? 'Por favor selecciona un lote'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Cultivo (ej. Mango, Aguacate o Limonaria)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Ingresa el nombre del cultivo'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _typeController,
                        decoration: InputDecoration(
                          labelText: 'Tipo (ej. Hortaliza / Frutal)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Ingresa el tipo' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Edad (años)',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Cantidad de plantas',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final cropsBox = Hive.box('crops');
                              cropsBox.add({
                                'farmKey': _selectedFarmKey,
                                'lotKey': _selectedLotKey,
                                'name': _nameController.text.trim(),
                                'type': _typeController.text.trim(),
                                'age': _ageController.text.trim(),
                                'quantity': _quantityController.text.trim(),
                              });
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Cultivo agregado exitosamente al lote')),
                              );
                            }
                          },
                          child: const Text('Guardar Cultivo',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: const Text('Gestión de Cultivos'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: _openBoxes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }
          return ValueListenableBuilder(
            valueListenable: Hive.box('crops').listenable(),
            builder: (context, Box cropsBox, _) {
              if (cropsBox.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay cultivos registrados.\nPresiona el botón + para agregar uno.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cropsBox.length,
                itemBuilder: (context, index) {
                  final crop = cropsBox.getAt(index) as Map;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFD8F3DC),
                        child: Icon(Icons.eco, color: Color(0xFF2D6A4F)),
                      ),
                      title: Text(crop['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Tipo: ${crop['type']} | Cantidad: ${crop['quantity']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent),
                        onPressed: () {
                          cropsBox.deleteAt(index);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddCropModal(context),
      ),
    );
  }
}