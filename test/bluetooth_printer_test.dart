import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_printer/bluetooth_printer.dart';
import 'package:bluetooth_printer/bluetooth_printer_platform_interface.dart';
import 'package:bluetooth_printer/bluetooth_printer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBluetoothPrinterPlatform
    with MockPlatformInterfaceMixin
    implements BluetoothPrinterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BluetoothPrinterPlatform initialPlatform = BluetoothPrinterPlatform.instance;

  test('$MethodChannelBluetoothPrinter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBluetoothPrinter>());
  });

  test('getPlatformVersion', () async {
    BluetoothPrinter bluetoothPrinterPlugin = BluetoothPrinter();
    MockBluetoothPrinterPlatform fakePlatform = MockBluetoothPrinterPlatform();
    BluetoothPrinterPlatform.instance = fakePlatform;

    expect(await bluetoothPrinterPlugin.getPlatformVersion(), '42');
  });
}
