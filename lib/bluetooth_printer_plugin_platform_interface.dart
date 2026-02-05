import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluetooth_printer_plugin_method_channel.dart';

abstract class BluetoothPrinterPlatform extends PlatformInterface {
  /// Constructs a BluetoothPrinterPlatform.
  BluetoothPrinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluetoothPrinterPlatform _instance = MethodChannelBluetoothPrinter();

  /// The default instance of [BluetoothPrinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluetoothPrinter].
  static BluetoothPrinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluetoothPrinterPlatform] when
  /// they register themselves.
  static set instance(BluetoothPrinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List<dynamic>?> getBondedDevices() {
    throw UnimplementedError('getBondedDevices() has not been implemented.');
  }

  Future<bool?> connect(String address) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  Future<bool?> write(String text) {
    throw UnimplementedError('write() has not been implemented.');
  }

  Future<bool?> requestBluetoothPermission() {
    throw UnimplementedError('requestBluetoothPermission() has not been implemented.');
  }
}
