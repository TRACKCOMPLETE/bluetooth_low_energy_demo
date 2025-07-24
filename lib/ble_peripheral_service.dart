import 'dart:async';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';
import 'gatt_definitions.dart';

class BLEPeripheralService {
  final PeripheralManager peripheralManager;
  late final GATTService gattService;

  final Set<Central> subscribedCentrals = {};

  BLEPeripheralService(this.peripheralManager) {
    gattService = createGattService();
    _listenNotifyState();
  }

  Future<void> startAdvertising(Advertisement advertisement) async {
    try {
      await peripheralManager.addService(gattService);
      debugPrint("✅ GATTサービス登録成功！");
    } catch (e) {
      debugPrint("❌ GATTサービス登録失敗: $e");
    }

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

  void _listenNotifyState() {
    peripheralManager.characteristicNotifyStateChanged.listen((event) {
      if (event.state) {
        subscribedCentrals.add(event.central);
        debugPrint("✅追加: ${event.central.uuid}");
      } else {
        subscribedCentrals.removeWhere((c) => c.uuid == event.central.uuid);
      }
    });
  }

  Future<void> sendText(String text) async {
    final value = Uint8List.fromList(text.codeUnits);

    // Notify対応のCharacteristicをちゃんと探す
    final notifyChara = gattService.characteristics.firstWhere(
          (c) => c.properties.contains(GATTCharacteristicProperty.notify),
      orElse: () => throw Exception("Notifyに対応したCharacteristicが見つかりません"),
    );

    for (final central in subscribedCentrals) {
      await peripheralManager.notifyCharacteristic(central, notifyChara, value: value);
    }

    debugPrint("📤 Notify送信: $text");
  }
}