import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:bluetooth_printer_plugin/bluetooth_printer_plugin.dart';

import 'network.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final _bluetoothPrinterPlugin = BluetoothPrinter();

  bool _isLoading = false;
  List<dynamic> _devices = [];

  String? _errorCode;

  String? _selectedAddress;

  Future<void> _init() async {
    try {
      setState(() { 
        _errorCode = null;
        _isLoading = true;
      });
      _devices = (await _bluetoothPrinterPlugin.getBondedDevices()) ?? [];
      print(_devices);
      setState(() { _isLoading = false; });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorCode = (e is PlatformException) ? e.code : 'UNKNOWN_ERROR';
      });
    }
  }

  Future<bool?> _allowBluetooth() async {
    try {
      bool? res = await _bluetoothPrinterPlugin.requestBluetoothPermission();
      return res;
    } catch(e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async { _init(); });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Plugin example app'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.wifi),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NetworkPrinterPage()),
                    );
                  },
                ),
              ],
            ),
            body: Center(
              child: SingleChildScrollView(
                child: _isLoading ? Center(
                  child: CircularProgressIndicator()
                ) : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.wifi),
                      label: const Text("Test Network Printer"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NetworkPrinterPage()),
                        );
                      },
                    ),
                    if(_errorCode == 'BLUETOOTH_PERMISSION_REQUIRED') Container(
                      constraints: BoxConstraints(
                        maxWidth: 250
                      ),
                      child: Column(
                        spacing: 16,
                        children: [
                          Text("Aplikasi membutuhkan akses ke bluetooth anda", textAlign: TextAlign.center),
                          ElevatedButton(onPressed: () async {
                            bool? res = await _allowBluetooth();
                            if(res == null) return;
                            if(res == true) _init();
                          }, child: Text("Beri Izin"))
                        ],
                      ),
                    ),
                    if(_errorCode == 'BLUETOOTH_NOT_ENABLED') Container(
                      constraints: BoxConstraints(
                        maxWidth: 250
                      ),
                      child: Column(
                        spacing: 16,
                        children: [
                          Text("Pastikan bluetooth pada perangkat anda menyala, lalu tekan tombol berikut", textAlign: TextAlign.center),
                          ElevatedButton(onPressed: () async {
                            _init();
                          }, child: Text("Reload"))
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(_errorCode ?? ""),
                    SizedBox(height: 20),
                    ..._devices.map((dynamic d) => ListTile(
                      title: Text(d["name"]),
                      subtitle: Text(d["address"]),
                      trailing: _selectedAddress == d["address"] ? Icon(Icons.check_circle) : null,
                      onTap: () {
                        setState(() {
                          _selectedAddress = d["address"];
                        });
                      },
                    )
                  )],
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(onPressed: () async {
                if(_selectedAddress == null) return;
                bool? connResult = await _bluetoothPrinterPlugin.connect(_selectedAddress!);
                if(connResult == true) {
                  await _bluetoothPrinterPlugin.write(
                    "\x1BM\x00"
                    "\x1Ba0Wajek Studio\n"
                    "\x1Ba1Jl. Bengawan No. 20\n"
                    "\x1Ba2HP/WA. 082143255597\n"
                  );
                }
              }, child: Text("Write to Selected Device")),
            ),
          );
        }
      ),
    );
  }
}
