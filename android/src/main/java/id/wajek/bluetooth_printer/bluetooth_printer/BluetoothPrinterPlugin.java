package id.wajek.bluetooth_printer.bluetooth_printer;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;
import androidx.core.app.ActivityCompat;

/** BluetoothPrinterPlugin */
public class BluetoothPrinterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, RequestPermissionsResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Activity activity;
  private MethodChannel.Result pendingResult;
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
      case "requestBluetoothPermission":
        requestBluetoothPermission(result);
        break;
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

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
    binding.addRequestPermissionsResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    this.activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    this.activity = null;
  }

  private void requestBluetoothPermission(@NonNull MethodChannel.Result result) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
      result.success(true);
      return;
    }

    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null);
      return;
    }

    pendingResult = result;
    ActivityCompat.requestPermissions(activity,
            new String[]{Manifest.permission.BLUETOOTH_CONNECT},
            1001);
  }

  @Override
  public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    if (requestCode == 1001) {
      if (pendingResult != null) {
        if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
          pendingResult.success(true);
        } else {
          pendingResult.error("BLUETOOTH_PERMISSION_DENIED", "Bluetooth permission denied", null);
        }
        pendingResult = null;
        return true;
      }
    }
    return false;
  }

  private void getBondedDevices(@NonNull Result result) {
    BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
    if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
      result.error("BLUETOOTH_PERMISSION_REQUIRED", "Bluetooth permission is required", null);
      return;
    }

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
