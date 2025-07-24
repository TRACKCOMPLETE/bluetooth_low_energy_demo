import 'dart:async';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';
import 'gatt_definitions.dart';

class BLEPeripheralService {
  final PeripheralManager peripheralManager;
  late final GATTService gattService;
  final Set<Central> subscribedCentrals = {};
  late final StreamSubscription _notifyStateSub;

  bool _serviceAdded = false;

  BLEPeripheralService(this.peripheralManager) {
    gattService = createGattService();
    _listenNotifyState();
  }

  Future<void> startAdvertising(Advertisement advertisement) async {
    try {
      if (!_serviceAdded) {
        await peripheralManager.addService(gattService);
        _serviceAdded = true;
        debugPrint("✅ GATTサービス登録成功！");
      }
    } catch (e) {
      debugPrint("❌ GATTサービス登録失敗: $e");
    }

    try {
      await peripheralManager.startAdvertising(advertisement);
      debugPrint("📢 アドバタイズ開始（サービスUUID: ${advertisement.serviceUUIDs}）");
    } catch (e) {
      debugPrint("❌ アドバタイズの開始に失敗しました: $e");
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await peripheralManager.stopAdvertising();
      debugPrint("🛑 アドバタイズを停止しました");
    } catch (e) {
      debugPrint("❌ アドバタイズの停止に失敗しました: $e");
    }
  }

  void _listenNotifyState() {
    peripheralManager.characteristicNotifyStateChanged.listen((event) {
      if (event.state) {
        subscribedCentrals.add(event.central);
        debugPrint("✅追加: ${event.central.uuid}");
      } else {
        subscribedCentrals.removeWhere((c) => c.uuid == event.central.uuid);
        debugPrint("🚫 通知の購読を解除した中央: ${event.central.uuid}");
      }
    });
  }

  Future<void> sendText(String text) async {
    if (subscribedCentrals.isEmpty) {
      debugPrint("⚠️ 送信先の中央がいません");
      return;
    }

    final value = Uint8List.fromList(text.codeUnits);
    final notifyChara = gattService.characteristics.firstWhere(
          (c) => c.properties.contains(GATTCharacteristicProperty.notify),
      orElse: () => throw Exception("Notifyに対応したCharacteristicが見つかりません"),
    );

    for (final central in subscribedCentrals) {
      try {
        await peripheralManager.notifyCharacteristic(central, notifyChara, value: value);
        debugPrint("📤 Notify送信: $text -> ${central.uuid}");
      } catch (e) {
        debugPrint("❌ Notify送信失敗: $e");
      }
    }
  }

  void dispose() {
    _notifyStateSub.cancel();
  }
}