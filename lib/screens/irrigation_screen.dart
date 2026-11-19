import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../services/auth_service.dart';

class IrrigationScreen extends StatefulWidget {
  final BluetoothDevice? connectedDevice;

  const IrrigationScreen({super.key, this.connectedDevice});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  String? _selectedFinca;
  String? _selectedLote;
  String? _selectedCultivo;

  List<String> _fincasList = [];
  List<String> _lotesList = [];
  List<String> _cropsList = [];

  bool _isConsulta = false;

  // Canal BLE real
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription<List<int>>? _rxSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  bool _sensorConnected = false;

  bool _isIrrigating = false;
  double _currentHumidity = 0.0;
  DateTime? _irrigationStartTime;

  bool _notifiedDry = false;
  bool _notifiedNearMax = false;

  static const double _minHumidityThreshold = 40.0;
  static const double _nearMaxThreshold = 75.0;
  static const double _maxHumidityThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadCreatedDataFromHive();
    _setupBluetoothCommunication();
  }

  @override
  void dispose() {
    _rxSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final user = await AuthService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _isConsulta = user.role.toLowerCase() == 'consulta';
      });
    }
  }

  Future<void> _loadCreatedDataFromHive() async {
    try {
      final farmsBox = Hive.isBoxOpen('farms') ? Hive.box('farms') : await Hive.openBox('farms');
      final lotsBox = Hive.isBoxOpen('lots') ? Hive.box('lots') : await Hive.openBox('lots');
      final cropsBox = Hive.isBoxOpen('crops') ? Hive.box('crops') : await Hive.openBox('crops');

      setState(() {
        _fincasList = farmsBox.values.map(_extractName).where((n) => n.isNotEmpty).toSet().toList();
        _lotesList = lotsBox.values.map(_extractName).where((n) => n.isNotEmpty).toSet().toList();
        _cropsList = cropsBox.values.map(_extractName).where((n) => n.isNotEmpty).toSet().toList();
      });

      if (_isConsulta) {
        _loadLastRecordedHumidity();
      }
    } catch (e) {
      debugPrint('Error cargando datos de Hive: $e');
    }
  }

  Future<void> _loadLastRecordedHumidity() async {
    try {
      final historyBox = Hive.isBoxOpen('history') ? Hive.box('history') : await Hive.openBox('history');
      if (historyBox.isNotEmpty) {
        final lastItem = Map<String, dynamic>.from(historyBox.values.last as Map);
        final rawHum = (lastItem['finalHumidity'] ?? '0').toString().replaceAll('%', '');
        final parsed = double.tryParse(rawHum);
        if (parsed != null && mounted && !_sensorConnected) {
          setState(() {
            _currentHumidity = parsed;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando última humedad para consulta: $e');
    }
  }

  String _extractName(dynamic item) {
    if (item == null) return '';
    if (item is String) return item.trim();
    if (item is Map) {
      return (item['name'] ?? item['nombre'] ?? item['title'] ?? item['crop'] ?? '').toString().trim();
    }
    try {
      return (item.name ?? '').toString().trim();
    } catch (_) {
      return item.toString().trim();
    }
  }

  Future<void> _setupBluetoothCommunication() async {
    BluetoothDevice? device = widget.connectedDevice;
    if (device == null && FlutterBluePlus.connectedDevices.isNotEmpty) {
      device = FlutterBluePlus.connectedDevices.first;
    }

    if (device == null) {
      if (!_isConsulta) {
        _showSnackBar('⚠️ No hay dispositivo ESP32 conectado.');
      }
      return;
    }

    // Monitorear si el ESP32 se desconecta en tiempo real
    await _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _sensorConnected = state == BluetoothConnectionState.connected;
          if (!_sensorConnected) {
            _txCharacteristic = null;
          }
        });
      }
    });

    try {
      if (!device.isConnected) {
        await device.connect(autoConnect: false);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        final sUuid = service.uuid.toString().toLowerCase();
        // Ignoramos los servicios genéricos del sistema Android (1800 y 1801)
        if (sUuid == '1800' || sUuid == '1801' || sUuid.startsWith('00001800') || sUuid.startsWith('00001801')) {
          continue;
        }

        for (var characteristic in service.characteristics) {
          // Canal RX del ESP32 (donde escribimos ON / OFF)
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _txCharacteristic = characteristic;
          }

          // Canal TX del ESP32 (donde leemos HUM:XX)
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            await _rxSubscription?.cancel();
            await characteristic.setNotifyValue(true);

            if (mounted) {
              setState(() => _sensorConnected = true);
            }

            _rxSubscription = characteristic.onValueReceived.listen((value) {
              if (value.isEmpty) return;
              final rawString = utf8.decode(value, allowMalformed: true).trim();
              final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(rawString);
              if (match != null && mounted) {
                final parsedHumidity = double.tryParse(match.group(0)!);
                if (parsedHumidity != null && parsedHumidity >= 0 && parsedHumidity <= 100) {
                  _processHumidityReading(parsedHumidity);
                }
              }
            });
          }
        }
      }

      if (_txCharacteristic != null && _sensorConnected) {
        _showSnackBar('✅ Sensor y bomba sincronizados con el ESP32');
      } else {
        _showSnackBar('⚠️ Reintentando enlazar canales del ESP32...');
        await Future.delayed(const Duration(seconds: 1));
        await device.discoverServices();
      }
    } catch (e) {
      _showSnackBar('Error BLE: $e');
    }
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year a las $hour:$minute';
  }

  String _formatOnlyTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _processHumidityReading(double humidity) {
    setState(() {
      _currentHumidity = humidity;
      _sensorConnected = true;
    });

    if (_isConsulta) return;
    if (_selectedFinca == null || _selectedLote == null || _selectedCultivo == null) return;

    // 1. Suelo seco (< 40%) -> Alerta y encendido automático de bomba
    if (_currentHumidity < _minHumidityThreshold && !_isIrrigating && !_notifiedDry) {
      _notifiedDry = true;
      _notifiedNearMax = false;
      _saveAlertAndNotify(
        title: 'Suelo Seco (${_currentHumidity.toStringAsFixed(0)}%)',
        message: 'El cultivo $_selectedCultivo en $_selectedLote está seco. Se activará la bomba de agua.',
        type: 'warning',
      );
      _toggleIrrigation(true, isAutomatic: true);
    }

    // 2. Cerca del umbral máximo (75% - 79%) -> Alerta preventiva
    if (_isIrrigating &&
        _currentHumidity >= _nearMaxThreshold &&
        _currentHumidity < _maxHumidityThreshold &&
        !_notifiedNearMax) {
      _notifiedNearMax = true;
      _saveAlertAndNotify(
        title: 'Casi en Umbral Máximo (${_currentHumidity.toStringAsFixed(0)}%)',
        message: 'El cultivo $_selectedCultivo en $_selectedLote está por llegar al límite óptimo (${_maxHumidityThreshold.toInt()}%).',
        type: 'info',
      );
    }

    // 3. Umbral máximo alcanzado (>= 80%) -> Apaga bomba y guarda en historial
    if (_isIrrigating && _currentHumidity >= _maxHumidityThreshold) {
      _saveAlertAndNotify(
        title: 'Umbral Máximo Alcanzado (${_currentHumidity.toStringAsFixed(0)}%)',
        message: 'Riego completado en $_selectedLote. Bomba de agua apagada.',
        type: 'success',
      );
      _toggleIrrigation(false, isAutomatic: true);
    }
  }

  Future<void> _toggleIrrigation(bool start, {bool isAutomatic = false}) async {
    if (_isConsulta) return;
    if (_selectedFinca == null || _selectedLote == null || _selectedCultivo == null) return;

    BluetoothDevice? device = widget.connectedDevice;
    if (device == null && FlutterBluePlus.connectedDevices.isNotEmpty) {
      device = FlutterBluePlus.connectedDevices.first;
    }

    // Si el ESP32 se desconectó, lo reconectamos automáticamente antes de enviar la orden
    if (device != null && !device.isConnected) {
      _showSnackBar('🔄 Reconectando con ESP32...');
      await _setupBluetoothCommunication();
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (_txCharacteristic != null) {
      final command = start ? 'ON' : 'OFF';
      try {
        await _txCharacteristic!.write(
          utf8.encode(command),
          withoutResponse: _txCharacteristic!.properties.writeWithoutResponse,
        );
      } catch (e) {
        // Si falló por desconexión momentánea, re-enlazamos y reintentamos una vez
        await _setupBluetoothCommunication();
        if (_txCharacteristic != null) {
          try {
            await _txCharacteristic!.write(
              utf8.encode(command),
              withoutResponse: _txCharacteristic!.properties.writeWithoutResponse,
            );
          } catch (err) {
            _showSnackBar('⚠️ El ESP32 se reinició o está fuera de alcance. Revisa su alimentación.');
            return;
          }
        } else {
          return;
        }
      }
    } else {
      _showSnackBar('⚠️ Canal de control no enlazado. Toca el ícono Bluetooth arriba para reconectar.');
      return;
    }

    if (start) {
      setState(() {
        _isIrrigating = true;
        _irrigationStartTime = DateTime.now();
        _notifiedNearMax = false;
      });
      if (!isAutomatic) {
        _showSnackBar('💧 Bomba encendida para $_selectedCultivo ($_selectedLote)');
      }
    } else {
      final endTime = DateTime.now();
      final durationSeconds = _irrigationStartTime != null
          ? endTime.difference(_irrigationStartTime!).inSeconds
          : 0;

      await _saveIrrigationToHistory(endTime, durationSeconds, isAutomatic);

      setState(() {
        _isIrrigating = false;
        _irrigationStartTime = null;
        _notifiedDry = false;
      });
    }
  }

  Future<void> _saveAlertAndNotify({
    required String title,
    required String message,
    required String type,
  }) async {
    final now = DateTime.now();
    try {
      final alertsBox = Hive.isBoxOpen('alerts') ? Hive.box('alerts') : await Hive.openBox('alerts');
      await alertsBox.add({
        'title': title,
        'message': message,
        'type': type,
        'finca': _selectedFinca,
        'lote': _selectedLote,
        'crop': _selectedCultivo,
        'humidity': _currentHumidity.toStringAsFixed(0),
        'time': _formatOnlyTime(now),
        'dateTime': _formatDateTime(now),
        'timestamp': now.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error guardando alerta en Hive: $e');
    }

    _showSnackBar('🔔 $title: $message');
  }

  Future<void> _saveIrrigationToHistory(DateTime endTime, int durationSeconds, bool isAutomatic) async {
    try {
      final historyBox = Hive.isBoxOpen('history') ? Hive.box('history') : await Hive.openBox('history');
      final dateTimeStr = _formatDateTime(endTime);

      await historyBox.add({
        'finca': _selectedFinca,
        'lote': _selectedLote,
        'loteName': _selectedLote,
        'crop': _selectedCultivo,
        'cultivo': _selectedCultivo,
        'date': dateTimeStr,
        'summary': 'Se regó el cultivo de $_selectedCultivo el día $dateTimeStr',
        'duration': '${durationSeconds}s',
        'finalHumidity': '${_currentHumidity.toStringAsFixed(0)}%',
        'mode': isAutomatic ? 'Automático (Sensor)' : 'Manual',
        'timestamp': endTime.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error guardando historial en Hive: $e');
    }
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1B4332),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool seleccionCompleta =
        _selectedFinca != null && _selectedLote != null && _selectedCultivo != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: Text(_isConsulta ? 'Monitoreo de Riego (Consulta)' : 'Control de Riego IoT'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (!_isConsulta)
            IconButton(
              icon: Icon(_sensorConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching),
              tooltip: 'Reconectar sensor ESP32',
              onPressed: _setupBluetoothCommunication,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isConsulta) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.visibility_rounded, color: Color(0xFF1565C0)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Modo Consulta (Solo Lectura): Puedes supervisar la humedad del lote, pero el accionamiento de la bomba está restringido al Productor.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Text(
              'Selección de Zona y Cultivo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedFinca,
              decoration: InputDecoration(
                labelText: _fincasList.isEmpty ? 'No hay fincas creadas' : 'Selecciona la Finca',
                prefixIcon: const Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _fincasList.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (value) => setState(() => _selectedFinca = value),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _selectedLote,
              decoration: InputDecoration(
                labelText: _lotesList.isEmpty ? 'No hay lotes creados' : 'Selecciona el Lote',
                prefixIcon: const Icon(Icons.terrain, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _lotesList.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (value) => setState(() => _selectedLote = value),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _selectedCultivo,
              decoration: InputDecoration(
                labelText: _cropsList.isEmpty ? 'No hay cultivos creados' : 'Selecciona el Cultivo',
                prefixIcon: const Icon(Icons.eco_rounded, color: Color(0xFF8E24AA)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _cropsList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => _selectedCultivo = value),
            ),
            const SizedBox(height: 20),

            if (seleccionCompleta) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sensor de Humedad',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isIrrigating ? Colors.blue.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isIrrigating
                                ? '💧 Bomba Encendida'
                                : (_sensorConnected
                                    ? 'Sensor Activo'
                                    : (_isConsulta ? 'Último Registro' : 'Esperando Sensor...')),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isIrrigating ? Colors.blue.shade700 : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 135,
                          height: 135,
                          child: CircularProgressIndicator(
                            value: _currentHumidity / 100,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade200,
                            color: _currentHumidity < _minHumidityThreshold
                                ? Colors.redAccent
                                : (_currentHumidity >= _nearMaxThreshold ? Colors.orange : const Color(0xFF2E7D32)),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${_currentHumidity.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                            Text(
                              _currentHumidity < _minHumidityThreshold
                                  ? 'Suelo Seco'
                                  : (_currentHumidity >= _nearMaxThreshold ? 'Casi Máximo' : 'Óptimo'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _currentHumidity < _minHumidityThreshold ? Colors.redAccent : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mín: ${_minHumidityThreshold.toInt()}% • Alerta: ${_nearMaxThreshold.toInt()}% • Máx: ${_maxHumidityThreshold.toInt()}%',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    if (_isConsulta)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: Color(0xFF2E7D32), size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _isIrrigating
                                    ? 'Válvula activa (Supervisión en vivo)'
                                    : 'Válvula en espera (Control exclusivo del Productor)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4332),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isIrrigating ? Colors.redAccent : const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _toggleIrrigation(!_isIrrigating),
                          icon: Icon(_isIrrigating ? Icons.stop_circle_outlined : Icons.water_drop_rounded),
                          label: Text(
                            _isIrrigating ? 'Apagar Bomba de Agua' : 'Iniciar Riego',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}