import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/utilities/support_contact.dart';
import '../../widgets/ui_kit.dart';

/// Langganan: lihat masa aktif, buat tagihan, bayar lewat QR DANA, lalu menunggu
/// admin mengaktifkan (status dicek otomatis tiap beberapa detik).
///
/// [standalone] = true bila dibuka dari layar masuk (langganan habis, belum masuk ke aplikasi).
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _qrAsset = 'assets/images/dana_qr.png';
  static const _monthOptions = [1, 3, 6, 12];

  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _info;
  Map<String, dynamic>? _invoice;
  int _months = 1;
  int _devices = 1;
  bool _paid = false;
  bool _claimed = false;
  Timer? _timer;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _call(String fn, [Map<String, dynamic>? params]) async {
    try {
      final raw = await _db.rpc(fn, params: params);
      return Map<String, dynamic>.from(raw as Map);
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak bisa terhubung ke server. Periksa internet Anda.'};
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _call('owner_billing_info');
    if (!mounted) return;
    if (res['status'] != 'ok') {
      setState(() {
        _error = res['message']?.toString() ?? 'Gagal memuat data langganan.';
        _loading = false;
      });
      return;
    }
    final min = (res['min_devices'] as num?)?.toInt() ?? 1;
    final pending = res['pending'];
    setState(() {
      _info = res;
      _devices = _devices < min ? min : _devices;
      if (pending is Map && _invoice == null) {
        _invoice = Map<String, dynamic>.from(pending);
        _claimed = _invoice!['claimed_at'] != null;
        _months = (_invoice!['months'] as num?)?.toInt() ?? _months;
        _devices = (_invoice!['devices'] as num?)?.toInt() ?? _devices;
      }
      _loading = false;
    });
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    if (_invoice == null || _paid) return;
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _poll());
  }

  Future<void> _poll() async {
    final code = _invoice?['code']?.toString();
    if (code == null || _paid) return;
    final res = await _call('owner_invoice_status', {'p_code': code});
    if (!mounted) return;
    if (res['status'] == 'ok' && res['invoice_status'] == 'paid') {
      _timer?.cancel();
      setState(() => _paid = true);
      final info = await _call('owner_billing_info');
      if (mounted && info['status'] == 'ok') setState(() => _info = info);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? cs.error : cs.tertiary));
  }

  Future<void> _createInvoice() async {
    setState(() => _busy = true);
    final res = await _call('owner_create_invoice', {'p_months': _months, 'p_devices': _devices});
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['status'] == 'ok' && res['invoice'] is Map) {
      setState(() {
        _invoice = Map<String, dynamic>.from(res['invoice'] as Map);
        _claimed = _invoice!['claimed_at'] != null;
        _paid = false;
      });
      _startPolling();
    } else {
      _toast(res['message']?.toString() ?? 'Gagal membuat tagihan.', error: true);
    }
  }

  Future<void> _claim() async {
    final code = _invoice?['code']?.toString();
    if (code == null) return;
    setState(() => _busy = true);
    final res = await _call('owner_claim_invoice', {'p_code': code});
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['status'] == 'ok') {
      setState(() => _claimed = true);
      _toast('Terkirim. Admin akan mengecek pembayaran Anda.');
    } else {
      _toast(res['message']?.toString() ?? 'Gagal mengirim.', error: true);
    }
  }

  void _newInvoice() {
    _timer?.cancel();
    setState(() {
      _invoice = null;
      _claimed = false;
      _paid = false;
    });
  }

  /// Buka WhatsApp developer dengan pesan berisi kode tagihan (unik per transaksi).
  /// Foto bukti bayar dilampirkan sendiri oleh owner di chat WhatsApp.
  Future<void> _sendProof(String code, int amount, Map<String, dynamic> inv) async {
    final email = _db.auth.currentUser?.email ?? '-';
    final msg = 'Halo, saya sudah bayar langganan Vecta POS.\n'
        'Kode tagihan: $code\n'
        'Paket: ${inv['devices']} HP x ${inv['months']} bulan\n'
        'Nominal: ${rp(amount)}\n'
        'Email akun: $email\n'
        'Bukti bayar saya lampirkan di chat ini.';
    await SupportContact.openWhatsApp(context, message: msg);
  }

  String _statusLabel(String s, bool expired) {
    if (expired) return 'Habis';
    return s == 'trial' ? 'Masa percobaan' : 'Aktif';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Langganan'),
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Coba lagi')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _statusCard(context),
                    const SizedBox(height: 14),
                    if (_paid) _paidCard(context) else if (_invoice != null) ..._invoiceSection(context) else ..._formSection(context),
                  ],
                ),
    );
  }

  Widget _statusCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final info = _info ?? const {};
    final exp = DateTime.tryParse('${info['expired_at'] ?? ''}')?.toLocal();
    final expired = exp != null && exp.isBefore(DateTime.now());
    final days = exp == null ? 0 : exp.difference(DateTime.now()).inDays;
    final color = expired ? cs.error : (days <= 5 ? Colors.orange : Colors.green);
    return SectionCard(
      child: Row(
        children: [
          IconBadge(icon: Icons.workspace_premium_rounded, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel('${info['sub_status'] ?? ''}', expired),
                  style: TextStyle(fontWeight: FontWeight.w800, color: color),
                ),
                Text(
                  exp == null
                      ? '-'
                      : expired
                          ? 'Habis sejak ${fmtDateTime(exp)}'
                          : 'Aktif sampai ${fmtDateTime(exp)} ($days hari lagi)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
                ),
                Text(
                  'HP terdaftar: ${info['devices_now'] ?? 0}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _formSection(BuildContext context) {
    final info = _info ?? const {};
    final unit = (info['unit_price'] as num?)?.toInt() ?? 20000;
    final min = (info['min_devices'] as num?)?.toInt() ?? 1;
    final total = unit * _devices * _months;
    return [
      const SectionTitle('Perpanjang langganan'),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lama langganan', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in _monthOptions)
                  ChoiceChip(
                    label: Text('$m bulan'),
                    selected: _months == m,
                    onSelected: (_) => setState(() => _months = m),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Jumlah HP', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                IconButton.outlined(
                  onPressed: _devices > min ? () => setState(() => _devices--) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('$_devices', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                IconButton.outlined(
                  onPressed: _devices < 50 ? () => setState(() => _devices++) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            Text(
              'Minimal $min HP (sesuai jumlah HP yang pernah dipakai pada akun ini).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(child: Text('${rp(unit)} x $_devices HP x $_months bulan')),
                Text(rp(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      PrimaryButton(
        label: _busy ? 'Memproses...' : 'Buat tagihan',
        icon: Icons.receipt_long_rounded,
        onTap: _busy ? null : _createInvoice,
      ),
      if (widget.standalone) ...[
        const SizedBox(height: 8),
        TextButton(onPressed: () => context.go('/sign-in'), child: const Text('Kembali ke halaman masuk')),
      ],
    ];
  }

  List<Widget> _invoiceSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inv = _invoice!;
    final code = '${inv['code']}';
    final amount = (inv['amount'] as num?)?.toInt() ?? 0;
    return [
      const SectionTitle('Tagihan Anda'),
      SectionCard(
        child: Column(
          children: [
            Text('Kode tagihan', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SelectableText(code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
                IconButton(
                  tooltip: 'Salin kode',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    _toast('Kode disalin');
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${inv['devices']} HP x ${inv['months']} bulan'),
            const SizedBox(height: 4),
            Text(rp(amount), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              'Bayar tepat sesuai nominal ini.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SectionCard(
        child: Column(
          children: [
            Image.asset(
              _qrAsset,
              width: 240,
              errorBuilder: (_, __, ___) => Container(
                width: 240,
                height: 120,
                alignment: Alignment.center,
                child: Text('Gambar QR belum dipasang\n($_qrAsset)', textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 8),
            Text('Scan QR DANA di atas', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cara bayar', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('1. Bayar ${rp(amount)} lewat QR DANA di atas.'),
            Text('2. Tulis kode $code di kolom catatan / pesan.'),
            const Text('3. Tekan "Saya sudah bayar" di bawah.'),
            const Text('4. Tekan "Kirim bukti ke WhatsApp", lalu lampirkan foto bukti bayar.'),
            const Text('5. Tunggu admin mengaktifkan. Halaman ini otomatis berubah.'),
            const SizedBox(height: 6),
            Text(
              'Tagihan tidak bisa diubah. Mengurangi jumlah HP setelah tagihan dibuat tidak mengurangi nominal.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      PrimaryButton(
        label: _claimed ? 'Menunggu admin mengecek...' : (_busy ? 'Mengirim...' : 'Saya sudah bayar'),
        icon: _claimed ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
        onTap: (_claimed || _busy) ? null : _claim,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => _sendProof(code, amount, inv),
        icon: const Icon(Icons.send_rounded),
        label: const Text('Kirim bukti ke WhatsApp'),
      ),
      const SizedBox(height: 8),
      TextButton(onPressed: _newInvoice, child: const Text('Ubah jumlah / buat tagihan baru')),
      if (widget.standalone)
        TextButton(onPressed: () => context.go('/sign-in'), child: const Text('Kembali ke halaman masuk')),
    ];
  }

  Widget _paidCard(BuildContext context) {
    final exp = DateTime.tryParse('${_info?['expired_at'] ?? ''}')?.toLocal();
    return SectionCard(
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
          const SizedBox(height: 8),
          Text('Pembayaran diterima', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            exp == null ? 'Langganan Anda aktif.' : 'Langganan aktif sampai ${fmtDateTime(exp)}.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (widget.standalone)
            PrimaryButton(label: 'Masuk ke aplikasi', icon: Icons.login_rounded, onTap: () => context.go('/sign-in'))
          else
            PrimaryButton(label: 'Selesai', icon: Icons.check_rounded, onTap: () => context.go('/account')),
          TextButton(onPressed: _newInvoice, child: const Text('Buat tagihan lain')),
        ],
      ),
    );
  }
}
