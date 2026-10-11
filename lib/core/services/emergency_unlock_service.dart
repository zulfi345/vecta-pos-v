import 'dart:convert';
import 'package:crypto/crypto.dart';

class EmergencyUnlockService {
  static const String _developerSecret = "VECTA_POS_EMERGENCY_SECRET_KEY_2026";

  static String generateUnlockCode(String deviceId) {
    final cleanDeviceId = deviceId.trim();
    final bytes = utf8.encode("$cleanDeviceId-$_developerSecret");
    final digest = sha256.convert(bytes);
    final shortToken = digest.toString().substring(0, 8).toUpperCase();
    return "VECTA-$shortToken";
  }

  static bool validateUnlockCode({
    required String inputCode,
    required String currentDeviceId,
  }) {
    if (inputCode.trim().isEmpty || currentDeviceId.trim().isEmpty) {
      return false;
    }
    final expectedCode = generateUnlockCode(currentDeviceId);
    return inputCode.trim().toUpperCase() == expectedCode;
  }
}
