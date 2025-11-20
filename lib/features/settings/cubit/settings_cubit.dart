import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/device_model.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final StorageService _storageService;
  final Connectivity _connectivity;
  final NetworkInfo _networkInfo;

  SettingsCubit({
    required StorageService storageService,
    required Connectivity connectivity,
    required NetworkInfo networkInfo,
  }) : _storageService = storageService,
       _connectivity = connectivity,
       _networkInfo = networkInfo,
       super(SettingsInitial()) {
    loadUrl();
  }

  Future<void> loadUrl() async {
    try {
      emit(SettingsLoading());
      final url = await _storageService.getUrl();
      final selectedWifiDeviceId = await _storageService
          .getSelectedWifiDevice();
      final selectedBluetoothDeviceId = await _storageService
          .getSelectedBluetoothDevice();
      emit(
        SettingsLoaded(
          savedUrl: url ?? '',
          wifiNetworks: [],
          bluetoothDevices: [],
          selectedWifiDeviceId: selectedWifiDeviceId,
          selectedBluetoothDeviceId: selectedBluetoothDeviceId,
        ),
      );
      // Automatically scan for devices after loading settings
      await scanAllDevices();
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> scanAllDevices() async {
    // Only scan if we have a loaded state
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // Scan both WiFi and Bluetooth devices in parallel
    // Each scan method handles its own errors and resets its scanning flag
    try {
      await Future.wait([
        scanWifiNetworks(),
        scanBluetoothDevices(),
      ]).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      // Ensure scanning flags are reset on timeout
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(state.copyWith(isScanningWifi: false, isScanningBluetooth: false));
      }
    } catch (e) {
      // Ensure scanning flags are reset on any error
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(state.copyWith(isScanningWifi: false, isScanningBluetooth: false));
      }
    }
  }

  Future<void> saveUrl(String url) async {
    try {
      if (!_isValidUrl(url)) {
        emit(SettingsError('Please enter a valid URL'));
        return;
      }

      emit(SettingsLoading());
      await _storageService.saveUrl(url);
      final currentState = state;
      if (currentState is SettingsLoaded) {
        emit(currentState.copyWith(savedUrl: url));
      } else {
        emit(
          SettingsLoaded(
            savedUrl: url,
            wifiNetworks: [],
            bluetoothDevices: [],
            selectedWifiDeviceId: null,
            selectedBluetoothDeviceId: null,
          ),
        );
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> scanWifiNetworks() async {
    try {
      var currentState = state;
      if (currentState is! SettingsLoaded) return;

      // Get fresh state and update scanning flag
      currentState = state as SettingsLoaded;
      emit(currentState.copyWith(isScanningWifi: true));

      // Request location permission (required for WiFi scanning on Android)
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        currentState = state as SettingsLoaded;
        emit(currentState.copyWith(isScanningWifi: false));
        return;
      }

      // Request WiFi permission
      final wifiStatus = await Permission.nearbyWifiDevices.request();
      if (!wifiStatus.isGranted) {
        currentState = state as SettingsLoaded;
        emit(currentState.copyWith(isScanningWifi: false));
        return;
      }

      final wifiNetworks = <DeviceModel>[];

      // Check current connectivity status
      final connectivityResults = await _connectivity.checkConnectivity();
      // Handle both List and single ConnectivityResult (varies by connectivity_plus version)
      bool isWifiConnected;
      if (connectivityResults is List) {
        final resultsList = connectivityResults as List<ConnectivityResult>;
        isWifiConnected = resultsList.contains(ConnectivityResult.wifi);
      } else {
        isWifiConnected = connectivityResults == ConnectivityResult.wifi;
      }

      if (isWifiConnected) {
        try {
          // Get WiFi information using network_info_plus
          final wifiName = await _networkInfo.getWifiName();
          final wifiBSSID = await _networkInfo.getWifiBSSID();

          // Remove quotes from SSID if present (Android sometimes returns SSID with quotes)
          final cleanWifiName =
              wifiName?.replaceAll('"', '') ?? 'Unknown Network';

          wifiNetworks.add(
            DeviceModel(
              id: wifiBSSID ?? 'current_wifi',
              name: cleanWifiName,
              type: DeviceType.wifi,
              address: wifiBSSID,
              isConnected: true,
            ),
          );
        } catch (e) {
          // If we can't get WiFi name, still show that WiFi is connected
          wifiNetworks.add(
            DeviceModel(
              id: 'current_wifi',
              name: 'Connected WiFi Network',
              type: DeviceType.wifi,
              isConnected: true,
            ),
          );
        }
      }

      // Get fresh state before emitting final result
      currentState = state as SettingsLoaded;
      emit(
        currentState.copyWith(
          wifiNetworks: wifiNetworks,
          isScanningWifi: false,
        ),
      );
    } catch (e) {
      // Always reset scanning flag, even on error
      final currentState = state;
      if (currentState is SettingsLoaded) {
        emit(
          currentState.copyWith(
            isScanningWifi: false,
            wifiNetworks: currentState.wifiNetworks,
          ),
        );
      }
    }
  }

  Future<void> scanBluetoothDevices() async {
    try {
      var currentState = state;
      if (currentState is! SettingsLoaded) return;

      // Get fresh state and update scanning flag
      currentState = state as SettingsLoaded;
      emit(currentState.copyWith(isScanningBluetooth: true));

      // Request Bluetooth permissions
      final bluetoothStatus = await Permission.bluetoothScan.request();
      if (!bluetoothStatus.isGranted) {
        currentState = state as SettingsLoaded;
        emit(
          currentState.copyWith(
            isScanningBluetooth: false,
            bluetoothDevices: [],
          ),
        );
        return;
      }

      final bluetoothConnectStatus = await Permission.bluetoothConnect
          .request();
      if (!bluetoothConnectStatus.isGranted) {
        currentState = state as SettingsLoaded;
        emit(
          currentState.copyWith(
            isScanningBluetooth: false,
            bluetoothDevices: [],
          ),
        );
        return;
      }

      // Check if Bluetooth is enabled
      final bluetoothState = await FlutterBluetoothSerial.instance.state;
      if (bluetoothState != BluetoothState.STATE_ON) {
        currentState = state as SettingsLoaded;
        emit(
          currentState.copyWith(
            isScanningBluetooth: false,
            bluetoothDevices: [],
          ),
        );
        return;
      }

      // Get bonded devices (already paired)
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial
          .instance
          .getBondedDevices();

      final bluetoothDevices = bondedDevices.map((device) {
        final deviceName = device.name ?? '';
        final lowerName = deviceName.toLowerCase();
        final isPrinter =
            lowerName.contains('printer') ||
            lowerName.contains('hp') ||
            lowerName.contains('canon') ||
            lowerName.contains('epson');

        return DeviceModel(
          id: device.address,
          name: deviceName.isNotEmpty ? deviceName : 'Unknown Device',
          type: isPrinter ? DeviceType.printer : DeviceType.bluetooth,
          address: device.address,
          isConnected: device.isConnected,
        );
      }).toList();

      // Get fresh state before emitting final result
      currentState = state as SettingsLoaded;
      emit(
        currentState.copyWith(
          bluetoothDevices: bluetoothDevices,
          isScanningBluetooth: false,
        ),
      );
    } catch (e) {
      // Always reset scanning flag, even on error
      final currentState = state;
      if (currentState is SettingsLoaded) {
        emit(
          currentState.copyWith(
            isScanningBluetooth: false,
            bluetoothDevices: currentState.bluetoothDevices,
          ),
        );
      }
    }
  }

  Future<void> selectDevice(String deviceId, DeviceType deviceType) async {
    try {
      final currentState = state;
      if (currentState is! SettingsLoaded) return;

      if (deviceType == DeviceType.wifi) {
        await _storageService.saveSelectedWifiDevice(deviceId);
        emit(currentState.copyWith(selectedWifiDeviceId: deviceId));
      } else if (deviceType == DeviceType.bluetooth ||
          deviceType == DeviceType.printer) {
        await _storageService.saveSelectedBluetoothDevice(deviceId);
        emit(currentState.copyWith(selectedBluetoothDeviceId: deviceId));
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
