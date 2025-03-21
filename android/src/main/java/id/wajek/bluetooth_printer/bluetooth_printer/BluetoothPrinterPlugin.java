package id.wajek.bluetooth_printer.bluetooth_printer;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** BluetoothPrinterPlugin */
public class BluetoothPrinterPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  BluetoothAdapter bluetoothAdapter;
  BluetoothDevice bluetoothDevice;
  BluetoothSocket bluetoothSocket;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "bluetooth_printer");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch(call.method) {
      case "getBondedDevices":
        getBondedDevices(result);
        break;
      case "connect":
        connect(result, call.argument("address"));
        break;
      case "write":
        write(result, call.argument("text"));
        break;
      default:
        result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  private void getBondedDevices(@NonNull Result result) {
    BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
    if (adapter == null) {
      result.error("BLUETOOTH_NOT_SUPPORTED", "Bluetooth is not supported on this device", null);
      return;
    }

    if (!adapter.isEnabled()) {
      result.error("BLUETOOTH_NOT_ENABLED", "Bluetooth is not enabled on this device", null);
      return;
    }

    Set<BluetoothDevice> bondedDevices = adapter.getBondedDevices();
    if (bondedDevices == null) {
      result.error("NO_BONDED_DEVICES", "No bonded devices found", null);
      return;
    }

    List<Map<String, Object>> deviceList = new ArrayList<>();
    for(BluetoothDevice d : bondedDevices) {
      deviceList.add(
        Map.of(
        "name", d.getName(),
        "address", d.getAddress()
        )
      );
    }
    result.success(deviceList);
  }

  private void connect(@NonNull Result result, String address) {
    bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
    if (bluetoothAdapter == null) {
      result.error("BLUETOOTH_NOT_SUPPORTED", "Bluetooth is not supported on this device", null);
      return;
    }

    if (!bluetoothAdapter.isEnabled()) {
      result.error("BLUETOOTH_NOT_ENABLED", "Bluetooth is not enabled on this device", null);
      return;
    }

    bluetoothDevice = bluetoothAdapter.getRemoteDevice(address);
    if (bluetoothAdapter == null) {
      result.error("DEVICE_NOT_FOUND", "Device not found", null);
      return;
    }

    try {
      if(bluetoothSocket != null && bluetoothSocket.isConnected()) bluetoothSocket.close();
      UUID uuid = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb");
      bluetoothSocket = bluetoothDevice.createRfcommSocketToServiceRecord(uuid);
      bluetoothSocket.connect();
      result.success(true);
    } catch(IOException e) {
      result.error("CONNECTION_FAILED", "Connection failed", null);
    }
  }

  public void write(@NonNull Result result, String text) {
    if(bluetoothSocket == null){
      result.error("NO_SOCKET_AVAILABLE", "Please connect to a device first", null);
      return;
    }

    if(!bluetoothSocket.isConnected()) {
      result.error("NOT_CONNECTED", "Please connect to a device first", null);
      return;
    }

    try {
      OutputStream outStream = bluetoothSocket.getOutputStream();
      byte[] bytes = text.getBytes();
      outStream.write(bytes);
      result.success(true);
    } catch (IOException e) {
      result.error("FAILED_TO_WRITE", "Failed to write specified data to device", null);
    }
  }

}
