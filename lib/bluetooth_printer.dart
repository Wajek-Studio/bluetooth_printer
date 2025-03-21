
import 'bluetooth_printer_platform_interface.dart';

class BluetoothPrinter {
  Future<String?> getPlatformVersion() {
    return BluetoothPrinterPlatform.instance.getPlatformVersion();
  }

  Future<List<dynamic>?> getBondedDevices() {
    return BluetoothPrinterPlatform.instance.getBondedDevices();
  }

  Future<bool?> connect(String address) {
    return BluetoothPrinterPlatform.instance.connect(address);
  }

  Future<bool?> write(String text) {
    return BluetoothPrinterPlatform.instance.write(text);
  }
}
