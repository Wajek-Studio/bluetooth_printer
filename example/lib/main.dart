import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:bluetooth_printer/bluetooth_printer.dart';

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

  String? _selectedAddress;

  Future<void> init() async {
    try {
      setState(() { _isLoading = true; });
      _devices = (await _bluetoothPrinterPlugin.getBondedDevices()) ?? [];
      setState(() { _isLoading = false; });
    } on PlatformException catch (e) {
      if (e.code == "BLUETOOTH_PERMISSION_REQUIRED") {
        await _bluetoothPrinterPlugin.requestBluetoothPermission();
        init();
        setState(() { _isLoading = false; });
      }
      if (e.code == "BLUETOOTH_PERMISSION_DENIED") {
        setState(() { _isLoading = false; });
      }
    } catch(e) {
      setState(() { _isLoading = false; });
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async { init(); });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: _isLoading ? Center(
            child: CircularProgressIndicator()
          ) : Column(
            children: [
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(onPressed: () async {
            if(_selectedAddress == null) return;
            bool? connResult = await _bluetoothPrinterPlugin.connect(_selectedAddress!);
            if(connResult == true) {
              await _bluetoothPrinterPlugin.write(
                "\x1BM\x00"
                "\x1Ba0Fish Market Banyuwangi\n"
                "\x1Ba1Jl. Bengawan No. 20\n"
                "\x1Ba2HP/WA. 082143255597\n"
              );
            }
            
          }, child: Text("Write to Selected Device")),
        ),
      ),
    );
  }
}
