import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_info_service.dart';
import '../services/license_service.dart';

class LicenseGate extends StatefulWidget {
  final Widget child;
  const LicenseGate({super.key, required this.child});

  @override
  State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> {
  final LicenseService _licenseService = LicenseService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  bool _isLoading = true;
  bool _isAuthorized = false;
  bool _isLocked = false;
  String _statusMessage = 'Memeriksa status lisensi perangkat...';
  String _deviceId = '';

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLicenseFlow();
  }

  static const _kExpiredAt = 'license_expired_at';
  static const _kLastSeen = 'license_last_seen';

  Future<void> _saveLicenseCache(DateTime expiredAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kExpiredAt, expiredAt.toIso8601String());
    await prefs.setInt(_kLastSeen, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _clearLicenseCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kExpiredAt);
    await prefs.remove(_kLastSeen);
  }

  /// True jika masa aktif tersimpan masih berlaku dan jam HP tidak dimundurkan.
  Future<bool> _isCachedLicenseValid() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kExpiredAt);
    final lastSeen = prefs.getInt(_kLastSeen);
    if (raw == null || lastSeen == null) return false;
    final expiredAt = DateTime.tryParse(raw);
    if (expiredAt == null) return false;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs < lastSeen - const Duration(minutes: 5).inMilliseconds) return false;
    if (nowMs > lastSeen) await prefs.setInt(_kLastSeen, nowMs);
    return DateTime.now().isBefore(expiredAt.add(const Duration(days: 3)));
  }

  Future<void> _checkLicenseFlow() async {
    _deviceId = await _deviceInfoService.getDeviceId();
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('owner_email');

    if (savedEmail == null || savedEmail.isEmpty) {
      setState(() {
        _isLoading = false;
        _isAuthorized = false;
        _statusMessage = 'Silakan masukkan Email Owner untuk mengaktifkan perangkat.';
      });
      return;
    }

    final result = await _licenseService.checkLicenseStatus(savedEmail);

    if (!mounted) return;

    if (result['status'] == 'active') {
      await _saveLicenseCache(result['expired_at'] as DateTime);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isAuthorized = true;
      });
    } else if (result['status'] == 'offline_error') {
      if (await _isCachedLicenseValid()) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isAuthorized = true;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLocked = true;
        _statusMessage = 'Tidak ada koneksi internet dan masa aktif tersimpan sudah habis.';
      });
    } else {
      await _clearLicenseCache();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLocked = true;
        _statusMessage = result['message'] ?? 'Lisensi tidak valid atau kedaluwarsa.';
      });
    }
  }

  Future<void> _handleRegisterEmail(String email) async {
    if (email.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Menghubungkan ke server...';
    });

    final result = await _licenseService.checkLicenseStatus(email.trim());

    if (!mounted) return;

    if (result['status'] == 'active') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('owner_email', email.trim());
      await _saveLicenseCache(result['expired_at'] as DateTime);

      setState(() {
        _isLoading = false;
        _isAuthorized = true;
      });
    } else {
      setState(() {
        _isLoading = false;
        _statusMessage = result['message'] ?? 'Gagal memverifikasi email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_statusMessage),
              ],
            ),
          ),
        ),
      );
    }

    if (_isAuthorized) {
      return widget.child;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Vecta POS - Aktivasi Perangkat')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Text('Device ID:\n$_deviceId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              Text(_statusMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              if (!_isLocked) ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Owner (Terdaftar di Supabase)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _handleRegisterEmail(_emailController.text),
                  child: const Text('Aktifkan Perangkat Ini'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade50,
                  child: const Text(
                    'Aplikasi perlu terhubung ke internet untuk memperbarui lisensi. Sambungkan internet atau perpanjang langganan Anda.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isLocked = false;
                      _statusMessage = 'Masukkan Email Owner untuk mencoba ulang.';
                    });
                  },
                  child: const Text('Coba Sambungkan Internet / Ubah Email'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
