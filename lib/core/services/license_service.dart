import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_info_service.dart';

class LicenseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  Future<Map<String, dynamic>> checkLicenseStatus(String ownerEmail) async {
    try {
      final deviceId = await _deviceInfoService.getDeviceId();
      final deviceName = await _deviceInfoService.getDeviceName();

      final res = await _supabase.rpc('check_license', params: {
        'p_email': ownerEmail,
        'p_device_id': deviceId,
        'p_device_name': deviceName,
      });

      final data = Map<String, dynamic>.from(res as Map);
      if (data['status'] == 'active') {
        return {
          'status': 'active',
          'expired_at': DateTime.parse(data['expired_at'] as String),
          'is_trial': data['is_trial'] == true,
          'device_id': deviceId,
        };
      }
      return data;
    } catch (e) {
      return {'status': 'offline_error', 'error': e.toString()};
    }
  }
}
