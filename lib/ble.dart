// 分けようとしてやめたもの
// 分けるとしたらこんな感じになる

import 'dart:async';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BluetoothLowEnergy {
  final CentralManager centralManager;
  final PeripheralManager peripheralManager;

  BluetoothLowEnergy()
      : centralManager = CentralManager(),
        peripheralManager = PeripheralManager();

  Future<void> initialize() async {
    try {
      debugPrint("Bluetooth Low Energy initialized successfully.");
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.message}");
    } catch (e) {
      debugPrint("Unexpected error: $e");
    }
  }

  Future<void> startAdvertising(
      {required String name, required UUID serviceUUID}) async {
    try {
      await peripheralManager.startAdvertising(
        Advertisement(
          name: name,
          serviceUUIDs: [serviceUUID],
        ),
      );
      debugPrint("Started advertising with name: $name");
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.message}");
    } catch (e) {
      debugPrint("Unexpected error: $e");
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await peripheralManager.stopAdvertising();
      debugPrint("Stopped advertising.");
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.message}");
    } catch (e) {
      debugPrint("Unexpected error: $e");
    }
  }

  Future<void> startScanning() async {
    try {
      await centralManager.startDiscovery();
      debugPrint("Started scanning for devices.");
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.message}");
    } catch (e) {
      debugPrint("Unexpected error: $e");
    }
  }

  Future<void> stopScanning() async {
    try {
      await centralManager.stopDiscovery();
      debugPrint("Stopped scanning for devices.");
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.message}");
    } catch (e) {
      debugPrint("Unexpected error: $e");
    }
  }

  Future<Object> getDiscoveredDevices() async {
    try {
      final devices = await centralManager.discovered;
      debugPrint("Discovered devices: ${devices.length}");
      return devices;
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.message}");
      return [];
    } catch (e) {
      debugPrint("Unexpected error: $e");
      return [];
    }
  }
}


