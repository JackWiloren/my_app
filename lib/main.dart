import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart' as uuid; // <-- добавлен префикс
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter BLE Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devices = [];
  final logger = Logger();

  String? _deviceUuid;

  @override
  void initState() {
    super.initState();
    _initUuid().then((_) => _initBle());
  }

  Future<void> _initUuid() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceUuid = prefs.getString('device_uuid');

    if (_deviceUuid == null) {
      _deviceUuid = uuid.Uuid().v4(); // <-- используется uuid с префиксом
      await prefs.setString('device_uuid', _deviceUuid!);
    }

    logger.d('UUID этого устройства: $_deviceUuid');
  }

  void _initBle() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    _ble.scanForDevices(withServices: []).listen((device) {
      if (_devices.every((d) => d.id != device.id)) {
        setState(() {
          _devices.add(device);
        });
        logger.d('Найдено устройство: ${device.name} | ID: ${device.id}');

        if (device.id == "d8:3a:dd:de:09:80") {
          _sendMessageToDevice(device.id);
        }
      }
    });
  }

  void _sendMessageToDevice(String macAddress) async {
    if (_deviceUuid == null) return;

    final serviceId = Uuid.parse("0000180d-0000-1000-8000-00805f9b34fb");
    final characteristicId = Uuid.parse("00002a37-0000-1000-8000-00805f9b34fb");

    try {
      await _ble.connectToDevice(id: macAddress).first;

      await _ble.writeCharacteristicWithResponse(
        QualifiedCharacteristic(
          serviceId: serviceId,
          characteristicId: characteristicId,
          deviceId: macAddress,
        ),
        value: _deviceUuid!.codeUnits,
      );

      logger.d("Отправлен UUID: $_deviceUuid");
    } catch (e) {
      logger.e("Ошибка при отправке: $e");
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
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
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Text(
              'BLE устройства поблизости:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return ListTile(
                    title: Text(
                      device.name.isNotEmpty ? device.name : '(неизвестно)',
                    ),
                    subtitle: Text('ID: ${device.id} | RSSI: ${device.rssi}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
