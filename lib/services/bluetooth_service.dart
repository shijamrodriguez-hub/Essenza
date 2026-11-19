import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class BluetoothController {
  BluetoothDevice? _targetDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  // Reemplaza con los UUIDs que tengas configurados en tu ESP32
  final String serviceUuid = "12345678-1234-1234-1234-1234567890ab";
  final String characteristicUuid = "87654321-4321-4321-4321-ba0987654321";

  bool get isConnected => _targetDevice != null;

  Future<bool> conectarBluetooth() async {
    try {
      // 1. Validar soporte de Bluetooth y activar si está apagado
      if (await FlutterBluePlus.isSupported == false) {
        print("El Bluetooth no es soportado en este dispositivo.");
        return false;
      }

      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      // 2. Iniciar escaneo BLE de forma nativa
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      var subscription = FlutterBluePlus.scanResults.listen((results) {
        for (var r in results) {
          if (r.device.platformName == "ESP32_Riego") {
            FlutterBluePlus.stopScan();
            _targetDevice = r.device;
            break;
          }
        }
      });

      await Future.delayed(const Duration(seconds: 4));
      subscription.cancel();
      await FlutterBluePlus.stopScan();

      if (_targetDevice == null) {
        print("No se encontró ningún dispositivo BLE cercano.");
        return false;
      }

      // 3. Conectar al dispositivo y descubrir servicios
      await _targetDevice!.connect();
      
      List<BluetoothService> services = await _targetDevice!.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
              _writeCharacteristic = characteristic;
            }
          }
        }
      }

      return true;
    } catch (e) {
      print("Error al conectar por Bluetooth: $e");
      return false;
    }
  }

  Future<void> enviarComando(String comando) async {
    if (_writeCharacteristic == null) {
      throw Exception("No hay una característica de escritura disponible.");
    }
    List<int> bytes = utf8.encode(comando);
    await _writeCharacteristic!.write(bytes);
  }

  void desconectar() {
    if (_targetDevice != null) {
      _targetDevice!.disconnect();
      _targetDevice = null;
      _writeCharacteristic = null;
    }
  }
}