import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';
import 'ble_central_service.dart';
import 'ble_peripheral_service.dart';
import 'gatt_definitions.dart';
import 'package:permission_handler/permission_handler.dart';

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
      home: const BLEHomePage(),
    );
  }
}

class BLEHomePage extends StatefulWidget {
  const BLEHomePage({super.key});

  @override
  State<BLEHomePage> createState() => _BLEHomePageState();
}

class _BLEHomePageState extends State<BLEHomePage> {
  late final CentralManager centralManager;
  late final PeripheralManager peripheralManager;
  late final BLECentralService centralService;
  late final BLEPeripheralService peripheralService;
  late final GATTService gattService;
  final textController = TextEditingController();

  List<DiscoveredEventArgs> discoveredDevices = [];
  Map<String, String> receivedTexts = {};

  bool advertisingIsOn = false;
  bool scanIsOn = false;

  @override
  void initState() {
    super.initState();

    requestPermissions();

    centralManager = CentralManager();
    peripheralManager = PeripheralManager();
    centralService = BLECentralService(centralManager);
    peripheralService = BLEPeripheralService(peripheralManager);
    gattService = createGattService();

    centralService.collectDiscoveredDeviceStream(
      central: centralManager,
      targetServiceUUID: serviceUUID, // 任意のUUID
    ).listen((event) {
      setState(() {
        discoveredDevices.add(event);
      });
    });

    centralService.notifiedStream.listen((event) {
      final uuid = event.peripheral.uuid.toString();
      final text = String.fromCharCodes(event.value);

      setState(() {
        receivedTexts[uuid] = text;
      });
    });
  }

  Future<void> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
      Permission.location,
    ].request();

    // 必要なら結果のログも出せる
    statuses.forEach((permission, status) {
      debugPrint('$permission: $status');
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Demo"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // アドバタイズ & スキャンボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (advertisingIsOn) {
                      // 今ONならSTOPする
                      await peripheralService.stopAdvertising();
                    } else {
                      // 今OFFならSTARTする
                      await peripheralService.startAdvertising(
                        Advertisement(
                          name: 'BLE_DEMO',
                          serviceUUIDs: [serviceUUID],
                        ),
                      );
                    }
                    setState(() {
                      advertisingIsOn = !advertisingIsOn;
                    });
                  },
                  child: Text(advertisingIsOn ? 'Stop Advertising' : 'Start Advertising'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (scanIsOn) {
                      await centralService.stopScanning();
                    } else {
                      await centralService.startScanning();
                    }
                    // 状態反転
                    setState(() {
                      scanIsOn = !scanIsOn;
                    });
                  },
                  child: Text(scanIsOn ? 'Stop Scanning' : 'Start Scanning'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 入力欄と送信ボタン
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: '送信文字列',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await peripheralService.sendText(textController.text);
              },
              child: const Text("送信"),
            ),
            const Divider(),
            const Text(
              "見つけたデバイス：",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = discoveredDevices[index].peripheral;
                  final advertisement = discoveredDevices[index].advertisement;
                  return Card(
                    child: ListTile(
                      title: Text(advertisement.name ?? '名前なし'),
                      subtitle: Text(receivedTexts[device.uuid.toString()] ?? device.uuid.toString(),),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          await centralService.connectToDevice(device);
                        },
                        child: const Text('接続'),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
