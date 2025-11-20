part of 'settings_cubit.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String savedUrl;
  final List<DeviceModel> wifiNetworks;
  final List<DeviceModel> bluetoothDevices;
  final String? selectedWifiDeviceId;
  final String? selectedBluetoothDeviceId;
  final bool isScanningWifi;
  final bool isScanningBluetooth;

  const SettingsLoaded({
    required this.savedUrl,
    required this.wifiNetworks,
    required this.bluetoothDevices,
    this.selectedWifiDeviceId,
    this.selectedBluetoothDeviceId,
    this.isScanningWifi = false,
    this.isScanningBluetooth = false,
  });

  SettingsLoaded copyWith({
    String? savedUrl,
    List<DeviceModel>? wifiNetworks,
    List<DeviceModel>? bluetoothDevices,
    String? selectedWifiDeviceId,
    String? selectedBluetoothDeviceId,
    bool? isScanningWifi,
    bool? isScanningBluetooth,
  }) {
    return SettingsLoaded(
      savedUrl: savedUrl ?? this.savedUrl,
      wifiNetworks: wifiNetworks ?? this.wifiNetworks,
      bluetoothDevices: bluetoothDevices ?? this.bluetoothDevices,
      selectedWifiDeviceId: selectedWifiDeviceId ?? this.selectedWifiDeviceId,
      selectedBluetoothDeviceId: selectedBluetoothDeviceId ?? this.selectedBluetoothDeviceId,
      isScanningWifi: isScanningWifi ?? this.isScanningWifi,
      isScanningBluetooth: isScanningBluetooth ?? this.isScanningBluetooth,
    );
  }

  @override
  List<Object?> get props => [
        savedUrl,
        wifiNetworks,
        bluetoothDevices,
        selectedWifiDeviceId,
        selectedBluetoothDeviceId,
        isScanningWifi,
        isScanningBluetooth,
      ];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

