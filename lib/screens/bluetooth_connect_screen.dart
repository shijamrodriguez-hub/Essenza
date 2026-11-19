import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'irrigation_screen.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            _scanResults = results;
          });
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Error al escanear: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await FlutterBluePlus.stopScan();
      await device.connect(autoConnect: false);
      // Precarga los servicios UART antes de navegar a la siguiente pantalla
      await device.discoverServices();

      if (mounted) {
        setState(() {
          _connectedDevice = device;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Conectado exitosamente al ESP32!"),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al conectar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al conectar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: const Text('Conexión Bluetooth ESP32'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Escanear de nuevo',
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dispositivos Bluetooth Cercanos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _scanResults.isEmpty
                  ? Center(
                      child: _isScanning
                          ? const CircularProgressIndicator(color: Color(0xFF2E7D32))
                          : const Text(
                              "No se encontraron dispositivos cercanos.\nAsegúrate de encender el ESP32.",
                              textAlign: TextAlign.center,
                            ),
                    )
                  : ListView.builder(
                      itemCount: _scanResults.length,
                      itemBuilder: (context, index) {
                        final data = _scanResults[index];
                        final deviceName = data.device.platformName.isNotEmpty
                            ? data.device.platformName
                            : "Dispositivo desconocido";
                        final isThisConnected = _connectedDevice?.remoteId == data.device.remoteId;

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.bluetooth, color: Color(0xFF8E24AA)),
                            title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(data.device.remoteId.toString()),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isThisConnected ? Colors.blueGrey : const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _connectToDevice(data.device),
                              child: Text(isThisConnected ? 'Conectado' : 'Conectar'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _connectedDevice != null ? const Color(0xFF2E7D32) : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _connectedDevice != null
                    ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IrrigationScreen(connectedDevice: _connectedDevice),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Siguiente (Seleccionar Cultivo)', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}