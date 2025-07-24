import 'dart:async';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BLECentralService {
  final CentralManager centralManager;
  final StreamController<GATTCharacteristicNotifiedEventArgs> _notifiedStreamController =
  StreamController.broadcast();

  BLECentralService(this.centralManager) {
    // 一度だけ listen して、外部に中継
    centralManager.characteristicNotified.listen((event) {
      _notifiedStreamController.add(event);
    });
  }

  Stream<GATTCharacteristicNotifiedEventArgs> get notifiedStream =>
      _notifiedStreamController.stream;

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

  Future<void> connectToDevice(Peripheral peripheral) async {
    try {
      // 接続処理（仮実装）
      await centralManager.connect(peripheral);

      // オプション：接続後にサービス・キャラクタリスティック探索とか
      final services = await centralManager.discoverGATT(peripheral);

      for (final service in services) {
        debugPrint("🔍 Service: ${service.uuid}");
        for (final characteristic in service.characteristics) {
          debugPrint("🧬 Characteristic: ${characteristic.uuid}");
          debugPrint("  ▶ Props: ${characteristic.properties}");
        }
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.contains(GATTCharacteristicProperty.notify)) {
            // Notify購読開始
            await centralManager.setCharacteristicNotifyState(
              peripheral,
              characteristic,
              state: true, // Notifyを有効にする
            );
          }
        }
      }

      if (kDebugMode) {
        print("✅ 接続成功: ${peripheral.uuid}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ 接続失敗: $e");
      }
    }
  }

  Stream<DiscoveredEventArgs> collectDiscoveredDeviceStream({
    required CentralManager central,
    required UUID targetServiceUUID, // ← 追加：このUUIDを持ってるやつだけ通す
  }) {
    final seenIds = <UUID>{};

    return central.discovered.where((event) {
      final uuid = event.peripheral.uuid;

      final advertisedServices = event.advertisement.serviceUUIDs;
      final hasTargetService = advertisedServices.contains(targetServiceUUID);

      return hasTargetService && seenIds.add(uuid);
    });
  }
}

