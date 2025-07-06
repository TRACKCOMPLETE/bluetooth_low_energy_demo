import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

UUID serviceUUID = UUID.fromString("12345678-1234-5678-1234-567812345678");
UUID characteristicUUID = UUID.fromString("87654321-4321-6789-4321-678987654321");

void main() {
  runApp(const BLEApp());
}

class BLEApp extends StatelessWidget {
  const BLEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const BLEHomePage(title: 'BLE Demo Home Page'),
    );
  }
}

class BLEHomePage extends StatefulWidget {
  const BLEHomePage({super.key, required this.title});

  final String title;

  @override
  State<BLEHomePage> createState() => _BLEHomePageState();
}

class _BLEHomePageState extends State<BLEHomePage> {
  final central = CentralManager();
  final peripheral = PeripheralManager();

  late GATTService gattService;

  List<DiscoveredEventArgs> devices = [];
  bool advertisingIsOn = false;
  bool scanIsOn = false;

  StreamSubscription<DiscoveredEventArgs>? _discoveredSubscription;

  @override
  void initState() {
    super.initState();

    gattService = GATTService(
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
              uuid: UUID.fromString("2901"),
              value: Uint8List.fromList("BLE Demo Characteristic".codeUnits),
            ),
          ],
        ),
      ],
    );

    _listenToAuthorization();

    // 1回だけlisten登録、重複防止のため
    _discoveredSubscription = central.discovered.listen((result) {
      if (!scanIsOn) return; // スキャンOFF時は無視

      setState(() {
        // UUIDで重複チェックしてから追加
        if (!devices.any((d) => d.peripheral.uuid == result.peripheral.uuid)) {
          devices.add(result);
        }
      });
    });
  }

  @override
  void dispose() {
    _discoveredSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenToAuthorization() async {
    central.stateChanged.listen((event) async {
      if (event.state == BluetoothLowEnergyState.unauthorized) {
        await central.authorize();
      }
    });

    peripheral.stateChanged.listen((event) async {
      if (event.state == BluetoothLowEnergyState.unauthorized) {
        await peripheral.authorize();
      }
    });
  }

  Future<void> _startAdvertising() async {
    await peripheral.addService(gattService);
    await peripheral.startAdvertising(
      Advertisement(
        name: 'BLE_DEMO',
        serviceUUIDs: [serviceUUID],
      ),
    );
  }

  void _advertising() async {
    if (advertisingIsOn) {
      await peripheral.stopAdvertising();
      setState(() {
        advertisingIsOn = false;
      });
      if(kDebugMode) {
        print("Advertising stopped");
      }
    } else {
      await _startAdvertising();
      setState(() {
        advertisingIsOn = true;
      });
    }
  }

  void _scanning() async {
    if (scanIsOn) {
      await central.stopDiscovery();
      setState(() {
        scanIsOn = false;
      });
      if(kDebugMode) {
        print("Scanning stopped");
      }
    } else {
      devices.clear();
      await central.startDiscovery(
          serviceUUIDs: [serviceUUID],
      );
      setState(() {
        scanIsOn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: _advertising,
                child:
                Text(advertisingIsOn ? 'Stop Advertising' : 'Start Advertising')),
            ElevatedButton(
                onPressed: _scanning,
                child: Text(scanIsOn ? 'Stop Scanning' : 'Start Scanning')),
            const Divider(),
            const Text("見つけたデバイス："),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    title: Text(device.advertisement.name ?? '名前なし'),
                    subtitle: Text(device.peripheral.uuid.toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}