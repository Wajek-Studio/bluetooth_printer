import 'package:esc_pos_utils/esc_pos_utils.dart';
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
                  final profile = await CapabilityProfile.load();
                  var generator = Generator(PaperSize.mm58, profile);
                  List<int> bytes = [];

                  bytes += generator.text(
                      'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
                  bytes += generator.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
                      styles: PosStyles(codeTable: 'CP1252'));
                  bytes += generator.text('Special 2: blåbærgrød',
                      styles: PosStyles(codeTable: 'CP1252'));

                  bytes += generator.text('Bold text', styles: PosStyles(bold: true));
                  bytes += generator.text('Reverse text', styles: PosStyles(reverse: true));
                  bytes += generator.text('Underlined text',
                      styles: PosStyles(underline: true), linesAfter: 1);
                  bytes +=
                      generator.text('Align left', styles: PosStyles(align: PosAlign.left));
                  bytes +=
                      generator.text('Align center', styles: PosStyles(align: PosAlign.center));
                  bytes += generator.text('Align right',
                      styles: PosStyles(align: PosAlign.right), linesAfter: 1);

                  bytes += generator.row([
                    PosColumn(
                      text: 'col3',
                      width: 3,
                      styles: PosStyles(align: PosAlign.center, underline: true),
                    ),
                    PosColumn(
                      text: 'col6',
                      width: 6,
                      styles: PosStyles(align: PosAlign.center, underline: true),
                    ),
                    PosColumn(
                      text: 'col3',
                      width: 3,
                      styles: PosStyles(align: PosAlign.center, underline: true),
                    ),
                  ]);

                  bytes += generator.text('Text size 200%',
                      styles: PosStyles(
                        height: PosTextSize.size2,
                        width: PosTextSize.size2,
                      ));

                  // Print image:
                  // final ByteData data = await rootBundle.load('assets/logo.png');
                  // final Uint8List imgBytes = data.buffer.asUint8List();
                  // final Image image = decodeImage(imgBytes)!;
                  // bytes += generator.image(image);
                  // Print image using an alternative (obsolette) command
                  // bytes += generator.imageRaster(image);

                  // Print barcode
                  final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
                  bytes += generator.barcode(Barcode.upcA(barData));

                  // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
                  // ticket.text(
                  //   'hello ! 中文字 # world @ éphémère &',
                  //   styles: PosStyles(codeTable: PosCodeTable.westEur),
                  //   containsChinese: true,
                  // );

                  bytes += generator.feed(2);
                  bytes += generator.cut();
                  await _bluetoothPrinterPlugin.write(bytes);
                }
              }, child: Text("Write to Selected Device")),
            ),
          );
        }
      ),
    );
  }
}
