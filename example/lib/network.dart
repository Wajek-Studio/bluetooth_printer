import 'dart:io';
import 'package:flutter/material.dart';

class NetworkPrinterPage extends StatefulWidget {
  const NetworkPrinterPage({super.key});

  @override
  State<NetworkPrinterPage> createState() => _NetworkPrinterPageState();
}

class _NetworkPrinterPageState extends State<NetworkPrinterPage> {
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.100");
  final TextEditingController _portController = TextEditingController(text: "9100");
  bool _isLoading = false;
  String _statusMessage = "";

  Future<void> _testPrint() async {
    final String ip = _ipController.text;
    final int port = int.tryParse(_portController.text) ?? 9100;

    setState(() {
      _isLoading = true;
      _statusMessage = "Connecting to $ip:$port...";
    });

    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

      setState(() {
        _statusMessage = "Connected. Sending data...";
      });

      // ESC/POS Commands
      // Initialize printer
      socket.add([0x1B, 0x40]); 

      // Center align
      socket.add([0x1B, 0x61, 0x01]);
      
      // Text
      socket.write("Wajek Studio\n");
      
      // Left align
      socket.add([0x1B, 0x61, 0x00]);
      socket.write("Jl. Bengawan No. 20\n");
      socket.write("HP/WA. 082143255597\n");
      socket.write("--------------------------------\n");
      socket.write("Test Print via Network TCP\n");
      socket.write("--------------------------------\n");
      socket.write("\n\n\n");

      // Cut paper (GS V 66 0)
      socket.add([0x1D, 0x56, 0x42, 0x00]);

      await socket.flush();
      await socket.close();

      setState(() {
        _statusMessage = "Print Success!";
      });

    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Printer Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: "Printer IP Address",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: "Printer Port",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _testPrint,
                child: const Text("Test Write Printer (TCP)"),
              ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.startsWith("Error") ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
