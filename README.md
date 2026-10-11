# Vecta POS

[![License: MIT](https://img.shields.io/badge/license-MIT-orange)](./LICENSE)
[![Made with Flutter](https://img.shields.io/badge/made%20with-Flutter-blue)](https://flutter.dev/)

Aplikasi kasir (POS) untuk UMKM yang dibuat dengan Flutter. Semua data disimpan di HP (SQLite) dan aplikasi tetap berjalan tanpa internet. Internet hanya dibutuhkan saat masuk (sign in) dengan Google.

## Fitur

- **Produk**: Tambah, ubah, hapus produk dengan foto, serta pantauan stok menipis
- **Kasir**: Keranjang belanja, transaksi, riwayat transaksi, dan manajemen shift kasir
- **Cetak Struk**: Printer thermal via USB, Bluetooth, BLE, atau jaringan (58mm, 72mm, 80mm)
- **Laporan**: Ringkasan penjualan, produk terlaris, dan pengeluaran
- **Usaha**: HPP, karyawan, absensi, dan pengeluaran
- **Akun**: Masuk dengan Google, profil, serta dukungan tema gelap dan terang

## Cara Menjalankan

1. Pasang [Flutter](https://flutter.dev/docs/get-started/install), lalu jalankan `flutter pub get`.
2. Buat proyek di [Firebase](https://firebase.google.com/), tambahkan aplikasi Android, dan aktifkan penyedia login Google. Firebase hanya dipakai untuk login.
3. Salin `config.example.json` menjadi `config.json`, lalu isi `GOOGLE_SERVER_CLIENT_ID` dengan Web client ID dari penyedia login Google di Firebase.
4. Jalankan aplikasi:

   ```sh
   flutter run --dart-define-from-file config.json
   ```

## Lisensi & Kredit

Vecta POS dikembangkan dari proyek open source Flutter POS oleh Elriz Wiraswara (Lisensi MIT).
