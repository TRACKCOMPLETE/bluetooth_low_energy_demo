import 'dart:async';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BLECentralService {
  final CentralManager centralManager;

  BLECentralService()
      : centralManager = CentralManager();


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

  Future<List<DiscoveredEventArgs>> collectDiscoveredDevices({
    required CentralManager central,
    Duration duration = const Duration(seconds: 5),
  }) async {
    final List<DiscoveredEventArgs> devices = [];
    final seenIds = <UUID>{};
    late StreamSubscription subscription;

    try {
      subscription = central.discovered.listen((result) {
        final uuid = result.peripheral.uuid;
        if (seenIds.add(uuid)) {
          devices.add(result);
        }
      });

      await Future.delayed(duration);
      await subscription.cancel();

      return devices;
    } catch (e) {
      debugPrint("Error collecting devices: $e");
      await subscription.cancel();
      return [];
    }
  }

}


