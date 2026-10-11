import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_info_service.dart';

class LicenseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  Future<Map<String, dynamic>> checkLicenseStatus(String ownerEmail) async {
    try {
      final deviceId = await _deviceInfoService.getDeviceId();
      final deviceName = await _deviceInfoService.getDeviceName();

      final subResponse = await _supabase
          .from('subscriptions')
          .select()
          .eq('owner_email', ownerEmail)
          .maybeSingle();

      if (subResponse == null) {
        return {'status': 'not_registered', 'message': 'Email belum terdaftar.'};
      }

      final expiredAt = DateTime.parse(subResponse['expired_at']);
      final isExpired = DateTime.now().isAfter(expiredAt);

      if (isExpired) {
        return {'status': 'expired', 'message': 'Masa aktif langganan habis.'};
      }

      await _supabase.from('devices').upsert({
        'owner_email': ownerEmail,
        'device_id': deviceId,
        'device_name': deviceName,
        'last_checkin': DateTime.now().toIso8601String(),
      }, onConflict: 'owner_email, device_id');

      return {
        'status': 'active',
        'expired_at': expiredAt,
        'device_id': deviceId,
      };
    } catch (e) {
      return {'status': 'offline_error', 'error': e.toString()};
    }
  }
}
