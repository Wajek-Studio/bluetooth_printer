# bluetooth_printer

A Flutter plugin for connecting to Bluetooth printers and sending print commands. This plugin supports Android devices and allows you to connect to bonded Bluetooth devices and send ESC/POS commands.

## Features

- 📱 Request Bluetooth permissions
- 🔍 Get list of bonded Bluetooth devices
- 🔗 Connect to Bluetooth printers
- 📄 Send text and ESC/POS commands to printers
- ⚡ Simple and easy-to-use API

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  bluetooth_printer:
    path: ../  # or your package path
```

Then run:

```bash
flutter pub get
```

## Android Setup

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

## Usage

### 1. Import the package

```dart
import 'package:bluetooth_printer/bluetooth_printer.dart';
```

### 2. Initialize the plugin

```dart
final _bluetoothPrinterPlugin = BluetoothPrinter();
```

### 3. Request Bluetooth Permission

Before using Bluetooth, you need to request permission from the user:

```dart
Future<bool?> requestPermission() async {
  try {
    bool? result = await _bluetoothPrinterPlugin.requestBluetoothPermission();
    return result;
  } catch (e) {
    print('Error requesting permission: $e');
    return null;
  }
}
```

### 4. Get Bonded Devices

Retrieve the list of already paired Bluetooth devices:

```dart
Future<void> getBondedDevices() async {
  try {
    List<dynamic>? devices = await _bluetoothPrinterPlugin.getBondedDevices();
    
    // Each device has 'name' and 'address' properties
    for (var device in devices ?? []) {
      print('Device: ${device["name"]} - ${device["address"]}');
    }
  } on PlatformException catch (e) {
    if (e.code == 'BLUETOOTH_PERMISSION_REQUIRED') {
      // Request permission first
      await requestPermission();
    } else if (e.code == 'BLUETOOTH_NOT_ENABLED') {
      // Ask user to enable Bluetooth
      print('Please enable Bluetooth');
    }
  }
}
```

### 5. Connect to a Printer

Connect to a Bluetooth device using its address:

```dart
Future<bool?> connectToPrinter(String deviceAddress) async {
  try {
    bool? connected = await _bluetoothPrinterPlugin.connect(deviceAddress);
    if (connected == true) {
      print('Successfully connected to printer');
    } else {
      print('Failed to connect');
    }
    return connected;
  } catch (e) {
    print('Error connecting: $e');
    return false;
  }
}
```

### 6. Print Text

Send text and ESC/POS commands to the connected printer:

```dart
Future<void> printReceipt() async {
  try {
    bool? result = await _bluetoothPrinterPlugin.write(
      "\x1BM\x00"  // ESC M - Select character font
      "\x1Ba0Fish Market Banyuwangi\n"  // ESC a - Center align
      "\x1Ba1Jl. Bengawan No. 20\n"
      "\x1Ba2HP/WA. 082143255597\n"
    );
    
    if (result == true) {
      print('Print successful');
    }
  } catch (e) {
    print('Error printing: $e');
  }
}
```

## Complete Example

Here's a complete example showing how to build a simple printer app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bluetooth_printer/bluetooth_printer.dart';

class PrinterApp extends StatefulWidget {
  @override
  State<PrinterApp> createState() => _PrinterAppState();
}

class _PrinterAppState extends State<PrinterApp> {
  final _bluetoothPrinterPlugin = BluetoothPrinter();
  
  bool _isLoading = false;
  List<dynamic> _devices = [];
  String? _errorCode;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDevices();
    });
  }

  Future<void> _loadDevices() async {
    try {
      setState(() {
        _errorCode = null;
        _isLoading = true;
      });
      
      _devices = (await _bluetoothPrinterPlugin.getBondedDevices()) ?? [];
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorCode = (e is PlatformException) ? e.code : 'UNKNOWN_ERROR';
      });
    }
  }

  Future<void> _requestPermission() async {
    bool? result = await _bluetoothPrinterPlugin.requestBluetoothPermission();
    if (result == true) {
      _loadDevices();
    }
  }

  Future<void> _printToDevice() async {
    if (_selectedAddress == null) return;
    
    bool? connected = await _bluetoothPrinterPlugin.connect(_selectedAddress!);
    if (connected == true) {
      await _bluetoothPrinterPlugin.write(
        "\x1BM\x00"
        "\x1Ba0Your Shop Name\n"
        "\x1Ba1Your Address\n"
        "\x1Ba2Contact Info\n"
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Printer'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _selectedAddress != null
          ? Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _printToDevice,
                child: Text('Print to Selected Device'),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_errorCode == 'BLUETOOTH_PERMISSION_REQUIRED') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bluetooth permission required'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestPermission,
              child: Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (_errorCode == 'BLUETOOTH_NOT_ENABLED') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please enable Bluetooth'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDevices,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return ListTile(
          title: Text(device['name']),
          subtitle: Text(device['address']),
          trailing: _selectedAddress == device['address']
              ? Icon(Icons.check_circle)
              : null,
          onTap: () {
            setState(() {
              _selectedAddress = device['address'];
            });
          },
        );
      },
    );
  }
}
```

## ESC/POS Commands

Common ESC/POS commands you can use:

| Command | Description |
|---------|-------------|
| `\x1BM\x00` | Select character font |
| `\x1Ba0` | Left align text |
| `\x1Ba1` | Center align text |
| `\x1Ba2` | Right align text |
| `\x1BE\x01` | Bold ON |
| `\x1BE\x00` | Bold OFF |
| `\x1Bd\x03` | Print and feed 3 lines |
| `\n` | Line feed |

## Error Handling

The plugin may throw `PlatformException` with these error codes:

- `BLUETOOTH_PERMISSION_REQUIRED` - User needs to grant Bluetooth permission
- `BLUETOOTH_NOT_ENABLED` - Bluetooth is disabled on the device
- `UNKNOWN_ERROR` - Other errors

## API Reference

### `getBondedDevices()`
Returns a list of bonded Bluetooth devices. Each device is a Map with `name` and `address` properties.

**Returns:** `Future<List<dynamic>?>`

### `connect(String address)`
Connects to a Bluetooth device using its MAC address.

**Parameters:**
- `address` - The MAC address of the device (e.g., "00:11:22:33:44:55")

**Returns:** `Future<bool?>` - `true` if connection successful

### `write(String text)`
Sends text data to the connected printer. Supports ESC/POS commands.

**Parameters:**
- `text` - The text or ESC/POS commands to send

**Returns:** `Future<bool?>` - `true` if write successful

### `requestBluetoothPermission()`
Requests Bluetooth permission from the user.

**Returns:** `Future<bool?>` - `true` if permission granted

### `getPlatformVersion()`
Gets the platform version.

**Returns:** `Future<String?>`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

