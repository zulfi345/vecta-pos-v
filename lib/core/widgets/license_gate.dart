import 'package:flutter/material.dart';

/// LicenseGate yang dilewati (bypass) agar aplikasi langsung menampilkan
/// halaman utama/login tanpa melalui layar aktivasi perangkat.
class LicenseGate extends StatelessWidget {
  final Widget child;
  const LicenseGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Langsung kembalikan aplikasi utama tanpa pengecekan atau layar aktivasi
    return child;
  }
}
