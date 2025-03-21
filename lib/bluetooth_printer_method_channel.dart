import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluetooth_printer_platform_interface.dart';

/// An implementation of [BluetoothPrinterPlatform] that uses method channels.
class MethodChannelBluetoothPrinter extends BluetoothPrinterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bluetooth_printer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<dynamic>?> getBondedDevices() async {
    final devices = await methodChannel.invokeMethod<List<dynamic>?>('getBondedDevices');
    return devices;
  }

  @override
  Future<bool?> connect(String address) async {
    final res = await methodChannel.invokeMethod<bool?>('connect', <String, dynamic>{
      "address": address
    });
    return res;
  }

  @override
  Future<bool?> write(String text) async {
    final res = await methodChannel.invokeMethod<bool?>('write', <String, dynamic>{
      "text": text
    });
    return res;
  }

    @override
  Future<bool?> requestBluetoothPermission() async {
    final res = await methodChannel.invokeMethod<bool?>('requestBluetoothPermission');
    return res;
  }
}
