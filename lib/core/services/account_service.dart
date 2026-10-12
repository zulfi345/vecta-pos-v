import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_info_service.dart';

/// Nama fungsi RPC di Supabase (schema public).
/// Kalau nama di dashboard Supabase Anda berbeda, ubah di sini saja.
class _Rpc {
  /// Cek / daftarkan HP owner. Param: p_device_id, p_device_name, p_register.
  /// Memakai auth.jwt(), jadi owner harus sudah login Supabase Auth.
  static const ownerSession = 'owner_check_license';

  /// Login karyawan. Param: p_email, p_pin, p_device_id, p_device_name.
  static const staffLogin = 'staff_login';

  /// Cek / logout sesi karyawan. Param: p_email, p_employee_id, p_device_id, p_logout.
  static const staffSession = 'staff_check';
}

/// Sesi masuk yang disimpan di HP.
class AccountSession {
  final String userId;
  final String email;
  final String? name;

  /// 'owner' atau 'staff'.
  final String role;
  final String? employeeCode;

  const AccountSession({
    required this.userId,
    required this.email,
    this.name,
    this.role = 'owner',
    this.employeeCode,
  });

  bool get isStaff => role == 'staff';

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'name': name,
        'role': role,
        'employeeCode': employeeCode,
      };

  static AccountSession? fromJson(Map<String, dynamic> j) {
    final id = j['userId']?.toString();
    final email = j['email']?.toString();
    if (id == null || id.isEmpty || email == null || email.isEmpty) return null;
    return AccountSession(
      userId: id,
      email: email,
      name: j['name']?.toString(),
      role: j['role']?.toString() ?? 'owner',
      employeeCode: j['employeeCode']?.toString(),
    );
  }
}

/// Mengurus login owner (email + sandi lewat Supabase Auth) dan karyawan
/// (email owner + PIN), sesi tersimpan, serta cache masa aktif untuk mode offline.
///
/// Semua method login/verifikasi mengembalikan Map dengan kunci `status`:
/// `active`, `expired`, `invalid_login`, `locked`, `pin_in_use`, `device_removed`,
/// `not_registered`, `unauthenticated`, `offline_error`, dst. (sesuai balasan RPC).
class AccountService {
  AccountService(this._prefs, {DeviceInfoService? deviceInfo, SupabaseClient? client})
      : _device = deviceInfo ?? DeviceInfoService(),
        _clientOverride = client;

  final SharedPreferences _prefs;
  final DeviceInfoService _device;
  final SupabaseClient? _clientOverride;

  SupabaseClient get _db => _clientOverride ?? Supabase.instance.client;

  static const _kSession = 'account_session';
  static const _kExpiredAt = 'account_expired_at';
  static const _kLastSeen = 'account_last_seen';

  // ───────────────────────── Sesi tersimpan ─────────────────────────

  AccountSession? get savedSession {
    final raw = _prefs.getString(_kSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AccountSession.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSession(AccountSession s) => _prefs.setString(_kSession, jsonEncode(s.toJson()));

  Future<void> clearSession() async {
    await _prefs.remove(_kSession);
    await _prefs.remove(_kExpiredAt);
    await _prefs.remove(_kLastSeen);
  }

  // ───────────────────── Cache masa aktif (offline) ─────────────────────

  Future<void> saveExpiry(DateTime expiredAt) async {
    await _prefs.setString(_kExpiredAt, expiredAt.toIso8601String());
    await _prefs.setInt(_kLastSeen, DateTime.now().millisecondsSinceEpoch);
  }

  /// True jika masa aktif tersimpan masih berlaku dan jam HP tidak dimundurkan.
  bool isCacheValid() {
    final raw = _prefs.getString(_kExpiredAt);
    final lastSeen = _prefs.getInt(_kLastSeen);
    if (raw == null || lastSeen == null) return false;
    final expiredAt = DateTime.tryParse(raw);
    if (expiredAt == null) return false;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs < lastSeen - const Duration(minutes: 5).inMilliseconds) return false;
    if (nowMs > lastSeen) unawaited(_prefs.setInt(_kLastSeen, nowMs));
    return DateTime.now().isBefore(expiredAt);
  }

  // ───────────────────────────── Login ─────────────────────────────

  /// Daftar owner baru: buat akun Supabase Auth, lalu daftarkan HP (langganan trial).
  Future<Map<String, dynamic>> registerOwner(String email, String password) async {
    try {
      final res = await _db.auth.signUp(email: email.trim(), password: password);
      if (res.session == null) {
        return _fail(
          'invalid_login',
          'Akun dibuat, tetapi perlu konfirmasi email. Cek email Anda lalu masuk.',
        );
      }
      return await _activateOwner(register: true);
    } on AuthException catch (e) {
      return _fail('invalid_login', _authMessage(e));
    } catch (e) {
      return _offline(e);
    }
  }

  /// Masuk sebagai owner. HP ini menjadi HP owner aktif (HP owner lain dilepas).
  Future<Map<String, dynamic>> signInOwner(String email, String password) async {
    try {
      await _db.auth.signInWithPassword(email: email.trim(), password: password);
      return await _activateOwner(register: true);
    } on AuthException catch (e) {
      return _fail('invalid_login', _authMessage(e));
    } catch (e) {
      return _offline(e);
    }
  }

  /// Masuk sebagai karyawan memakai email owner dan PIN.
  Future<Map<String, dynamic>> signInStaff(String ownerEmail, String pin) async {
    try {
      final deviceId = await _device.getDeviceId();
      final deviceName = await _device.getDeviceName();
      final raw = await _db.rpc(_Rpc.staffLogin, params: {
        'p_email': ownerEmail.trim(),
        'p_pin': pin.trim(),
        'p_device_id': deviceId,
        'p_device_name': deviceName,
      });
      final data = _asMap(raw);
      if (data['status'] != 'active') return data;

      final expiredAt = DateTime.parse(data['expired_at'] as String);
      final employeeId = data['employee_id'].toString();
      await _saveSession(AccountSession(
        userId: employeeId,
        email: (data['email'] ?? ownerEmail).toString(),
        name: data['employee_name']?.toString(),
        role: 'staff',
        employeeCode: data['employee_code']?.toString(),
      ));
      await saveExpiry(expiredAt);
      return {...data, 'expired_at': expiredAt};
    } catch (e) {
      return _offline(e);
    }
  }

  // ─────────────────────── Verifikasi & keluar ───────────────────────

  /// Cek ke server apakah sesi tersimpan masih sah.
  /// `expired_at` pada hasil bertipe [DateTime] bila status `active`.
  Future<Map<String, dynamic>> verifySaved(AccountSession s) async {
    try {
      final deviceId = await _device.getDeviceId();

      if (s.isStaff) {
        final raw = await _db.rpc(_Rpc.staffSession, params: {
          'p_email': s.email,
          'p_employee_id': s.userId,
          'p_device_id': deviceId,
          'p_logout': false,
        });
        return _normalize(_asMap(raw));
      }

      if (_db.auth.currentSession == null) {
        return _fail('invalid_login', 'Sesi habis. Silakan masuk lagi.');
      }
      final raw = await _db.rpc(_Rpc.ownerSession, params: {
        'p_device_id': deviceId,
        'p_device_name': await _device.getDeviceName(),
        'p_register': false,
      });
      return _normalize(_asMap(raw));
    } catch (e) {
      return _offline(e);
    }
  }

  Future<void> signOut() async {
    final s = savedSession;
    try {
      if (s != null && s.isStaff) {
        await _db.rpc(_Rpc.staffSession, params: {
          'p_email': s.email,
          'p_employee_id': s.userId,
          'p_device_id': await _device.getDeviceId(),
          'p_logout': true,
        });
      } else {
        await _db.auth.signOut();
      }
    } catch (_) {
      // Tetap keluar secara lokal walau server tidak terjangkau.
    }
    await clearSession();
  }

  // ───────────────────────────── Internal ─────────────────────────────

  Future<Map<String, dynamic>> _activateOwner({required bool register}) async {
    final user = _db.auth.currentUser;
    if (user == null) return _fail('unauthenticated', 'Silakan masuk dengan email dan sandi.');

    final raw = await _db.rpc(_Rpc.ownerSession, params: {
      'p_device_id': await _device.getDeviceId(),
      'p_device_name': await _device.getDeviceName(),
      'p_register': register,
    });
    final data = _normalize(_asMap(raw));
    if (data['status'] != 'active') return data;

    final email = (data['email'] ?? user.email ?? '').toString();
    await _saveSession(AccountSession(
      userId: user.id,
      email: email,
      name: email.contains('@') ? email.split('@').first : email,
      role: 'owner',
    ));
    await saveExpiry(data['expired_at'] as DateTime);
    return data;
  }

  Map<String, dynamic> _asMap(Object? raw) => Map<String, dynamic>.from(raw as Map);

  /// Ubah `expired_at` (String ISO) menjadi DateTime bila status active.
  Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    if (data['status'] == 'active' && data['expired_at'] is String) {
      return {...data, 'expired_at': DateTime.parse(data['expired_at'] as String)};
    }
    return data;
  }

  Map<String, dynamic> _fail(String status, String message) => {'status': status, 'message': message};

  Map<String, dynamic> _offline(Object e) {
    final isNetwork = e is SocketException || e is TimeoutException || e is HttpException ||
        e.toString().contains('ClientException') || e.toString().contains('SocketException');
    return {
      'status': 'offline_error',
      'message': isNetwork
          ? 'Tidak ada koneksi internet. Sambungkan internet untuk masuk.'
          : 'Terjadi kesalahan: $e',
      'error': e.toString(),
    };
  }

  String _authMessage(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) return 'Email atau sandi salah.';
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Email sudah terdaftar. Silakan masuk.';
    }
    if (m.contains('password')) return 'Sandi minimal 6 karakter.';
    if (m.contains('confirm')) return 'Email belum dikonfirmasi. Cek email Anda.';
    return e.message;
  }
}
