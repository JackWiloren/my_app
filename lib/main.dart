import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _initBle();
  }

  // Инициализация BLE и запрос разрешений
  void _initBle() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // Запуск сканирования
    _ble.scanForDevices(withServices: []).listen((device) {
      if (_devices.every((d) => d.id != device.id)) {
        setState(() {
          _devices.add(device);
        });
        print('Найдено устройство: ${device.name} | ID: ${device.id}');

        // Проверка на конкретный MAC-адрес
        if (device.id == "XX:XX:XX:XX:XX:XX") {
          // Замените на нужный MAC
          _sendMessageToDevice(device.id);
        }
      }
    });
  }

  // Метод для отправки сообщения устройству
  void _sendMessageToDevice(String macAddress) async {
    print('Отправка сообщения на устройство с MAC $macAddress');
    // Здесь добавьте код для отправки сообщения через BLE
    // Пример:
    // await _ble.writeCharacteristicWithResponse(characteristic, value: [0x01, 0x02]);
  }

  // Увеличение счётчика
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
