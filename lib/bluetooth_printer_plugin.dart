
import 'bluetooth_printer_plugin_platform_interface.dart';

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

  Future<bool?> write(List<int> data) {
    return BluetoothPrinterPlatform.instance.write(data);
  }

  Future<bool?> requestBluetoothPermission() {
    return BluetoothPrinterPlatform.instance.requestBluetoothPermission();
  }
}
