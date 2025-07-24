import 'dart:typed_data';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

/// サービスUUID（固定で使いたい場合）
final UUID serviceUUID = UUID.fromString("12345678-1234-5678-1234-567812345678");

/// キャラクタリスティックUUID（読み書き通知対応）
final UUID characteristicUUID = UUID.fromString("87654321-4321-6789-4321-678987654321");

/// ディスクリプタUUID（2901はキャラの説明用に使われるやつ）
final UUID descriptorUUID = UUID.fromString("2901");

/// GATTサービスを生成して返す
GATTService createGattService() {
  return GATTService(
    uuid: serviceUUID,
    isPrimary: true,
    includedServices: [],
    characteristics: [
      GATTCharacteristic.mutable(
        uuid: characteristicUUID,
        properties: [
          GATTCharacteristicProperty.read,
          GATTCharacteristicProperty.write,
          GATTCharacteristicProperty.notify,
        ],
        permissions: [
          GATTCharacteristicPermission.read,
          GATTCharacteristicPermission.write,
        ],
        descriptors: [
          GATTDescriptor.immutable(
            uuid: descriptorUUID,
            value: Uint8List.fromList("BLE Demo Characteristic".codeUnits),
          ),
        ],
      ),
    ],
  );
}
