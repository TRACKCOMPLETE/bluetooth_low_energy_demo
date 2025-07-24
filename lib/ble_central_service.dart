import 'dart:async';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BLECentralService {
  final CentralManager centralManager;
  final StreamController<GATTCharacteristicNotifiedEventArgs> _notifiedStreamController =
  StreamController.broadcast();

  final Set<UUID> connectedDevices = {};

  BLECentralService(this.centralManager) {
    centralManager.characteristicNotified.listen((event) {
      _notifiedStreamController.add(event);
    });

    centralManager.connectionStateChanged.listen((event) {
      if (event.state == ConnectionState.disconnected) {
        connectedDevices.remove(event.peripheral.uuid);
        debugPrint("🔌 切断検知: ${event.peripheral.uuid}");
      }
    });
  }

  Stream<GATTCharacteristicNotifiedEventArgs> get notifiedStream =>
      _notifiedStreamController.stream;

  Future<void> startScanning() async {
    try {
      await centralManager.startDiscovery();
      debugPrint("🔍 スキャンを開始しました");
    } on PlatformException catch (e) {
      debugPrint("⚠️ PlatformException（スキャン開始時）: ${e.message}");
    } catch (e) {
      debugPrint("⚠️ 予期しないエラー（スキャン開始時）: $e");
    }
  }

  Future<void> stopScanning() async {
    try {
      await centralManager.stopDiscovery();
      debugPrint("🛑 スキャンを停止しました");
    } on PlatformException catch (e) {
      debugPrint("⚠️ PlatformException（スキャン停止時）: ${e.message}");
    } catch (e) {
      debugPrint("⚠️ 予期しないエラー（スキャン停止時）: $e");
    }
  }

  Future<void> connectToDevice(Peripheral peripheral) async {
    try {
      await centralManager.connect(peripheral);
      debugPrint("✅ デバイスに接続成功: ${peripheral.uuid}");

      final services = await centralManager.discoverGATT(peripheral);

      for (final service in services) {
        debugPrint("🔧 サービス: ${service.uuid}");
        for (final characteristic in service.characteristics) {
          debugPrint("🧬 キャラクタリスティック: ${characteristic.uuid}");
          debugPrint("  ▶ 特性: ${characteristic.properties}");
        }

        for (final characteristic in service.characteristics) {
          if (characteristic.properties.contains(GATTCharacteristicProperty.notify)) {
            await centralManager.setCharacteristicNotifyState(
              peripheral,
              characteristic,
              state: true,
            );
            debugPrint("📩 Notify購読を開始: ${characteristic.uuid}");
          }
        }
      }
    } catch (e) {
      debugPrint("❌ デバイス接続に失敗: $e");
    }
  }

  Future<void> disconnectFromDevice(Peripheral peripheral) async {
    try {
      final services = await centralManager.discoverGATT(peripheral);

      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.contains(GATTCharacteristicProperty.notify)) {
            await centralManager.setCharacteristicNotifyState(
              peripheral,
              characteristic,
              state: false,
            );
            debugPrint("📴 Notify購読を解除: ${characteristic.uuid}");
          }
        }
      }
      await centralManager.disconnect(peripheral);
      connectedDevices.remove(peripheral.uuid);
      debugPrint("👋 切断成功: ${peripheral.uuid}");
    } catch (e) {
      debugPrint("❌ 切断失敗: $e");
    }
  }

  void dispose() {
    _notifiedStreamController.close();
  }

  Stream<DiscoveredEventArgs> collectDiscoveredDeviceStream({
    required CentralManager central,
    required UUID targetServiceUUID,
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

