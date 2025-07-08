import 'dart:async';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BLEPeripheralService {
  final PeripheralManager peripheralManager;

  BLEPeripheralService()
      : peripheralManager = PeripheralManager();

  Future<void> startAdvertising(Advertisement advertisement) async {
    try {
      await peripheralManager.startAdvertising(advertisement);
      debugPrint("Started advertising service: ${advertisement.serviceUUIDs}");
    } catch (e) {
      debugPrint("Error starting advertising: $e");
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await peripheralManager.stopAdvertising();
      debugPrint("Stopped advertising.");
    } catch (e) {
      debugPrint("Error stopping advertising: $e");
    }
  }
}