import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoService {
  static const _kInstallId = 'install_device_id';
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// ID unik per pemasangan aplikasi: dibuat sekali lalu disimpan di HP.
  /// Pasang ulang / hapus data aplikasi = ID baru (dianggap perangkat baru).
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kInstallId);
    if (saved != null && saved.isNotEmpty) return saved;
    final rnd = Random.secure();
    final id = List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(_kInstallId, id);
    return id;
  }

  Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      }
      return 'Unknown Terminal';
    } catch (e) {
      return 'Unknown Device';
    }
  }
}
