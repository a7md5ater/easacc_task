import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth_data_model.dart';

class StorageService {
  final SharedPreferences _prefs;

  static const String _keyUrl = 'saved_url';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyAuthProvider = 'auth_provider';
  static const String _keySelectedWifiDevice = 'selected_wifi_device';
  static const String _keySelectedBluetoothDevice = 'selected_bluetooth_device';

  StorageService({required SharedPreferences sharedPreferences})
    : _prefs = sharedPreferences;

  Future<void> saveUrl(String url) async {
    await _prefs.setString(_keyUrl, url);
  }

  Future<String?> getUrl() async {
    return _prefs.getString(_keyUrl);
  }

  Future<void> saveAuthData(String token, String provider) async {
    await _prefs.setString(_keyAuthToken, token);
    await _prefs.setString(_keyAuthProvider, provider);
  }

  Future<AuthDataModel?> getAuthData() async {
    final token = _prefs.getString(_keyAuthToken);
    final provider = _prefs.getString(_keyAuthProvider);

    if (token != null && provider != null) {
      return AuthDataModel(token: token, provider: provider);
    }
    return null;
  }

  Future<void> clearAuthData() async {
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyAuthProvider);
  }

  Future<void> saveSelectedWifiDevice(String deviceId) async {
    await _prefs.setString(_keySelectedWifiDevice, deviceId);
  }

  Future<String?> getSelectedWifiDevice() async {
    return _prefs.getString(_keySelectedWifiDevice);
  }

  Future<void> saveSelectedBluetoothDevice(String deviceId) async {
    await _prefs.setString(_keySelectedBluetoothDevice, deviceId);
  }

  Future<String?> getSelectedBluetoothDevice() async {
    return _prefs.getString(_keySelectedBluetoothDevice);
  }
}
