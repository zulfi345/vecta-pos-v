import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/services/device_info_service.dart' as dev;
import '../../widgets/ui_kit.dart';

/// Daftar HP yang terdaftar pada akun owner. Khusus HP owner (fungsi `owner_manage`).
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  bool _loading = true;
  String? _error;
  String _myId = '';
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final account = ref.read(accountServiceProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    final myId = await dev.DeviceInfoService().getDeviceId();
    final res = await account.manage('list_devices');
    if (!mounted) return;
    if (res['status'] == 'ok') {
      final raw = (res['items'] as List?) ?? const [];
      setState(() {
        _myId = myId;
        _items = [for (final e in raw) Map<String, dynamic>.from(e as Map)];
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Gagal memuat daftar HP.';
        _loading = false;
      });
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? cs.error : cs.tertiary));
  }

  Future<void> _remove(String deviceId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus HP'),
        content: const Text('HP ini akan dihapus dari daftar. Karyawan di HP itu harus masuk lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await ref.read(accountServiceProvider).manage('remove_device', {'target_device_id': deviceId});
    if (!mounted) return;
    if (res['status'] == 'ok') {
      _toast('HP dihapus.');
      await _load();
    } else {
      _toast(res['message']?.toString() ?? 'Gagal menghapus HP.', error: true);
    }
  }

  String _fmt(Object? v) {
    final d = DateTime.tryParse('${v ?? ''}')?.toLocal();
    if (d == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HP Terdaftar'),
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
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Coba lagi')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    SectionCard(
                      child: Row(
                        children: [
                          const IconBadge(icon: Icons.phone_android_rounded, color: Colors.teal),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Jumlah HP terdaftar: ${_items.length}. Tagihan dihitung dari jumlah HP.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_items.isEmpty)
                      const EmptyHint(icon: Icons.phone_android_rounded, text: 'Belum ada HP terdaftar')
                    else
                      for (final e in _items) _tile(context, e),
                  ],
                ),
    );
  }

  Widget _tile(BuildContext context, Map<String, dynamic> e) {
    final cs = Theme.of(context).colorScheme;
    final id = '${e['device_id']}';
    final isOwnerDevice = e['role'] == 'owner';
    final isMine = id == _myId;
    final label = isOwnerDevice ? 'Owner' : 'Karyawan: ${e['employee_name'] ?? '-'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            IconBadge(
              icon: Icons.phone_android_rounded,
              color: isOwnerDevice ? Colors.indigo : Colors.teal,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e['name'] ?? 'HP'}${isMine ? ' (HP ini)' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '$label • Terakhir: ${_fmt(e['last_checkin'])}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            if (!isOwnerDevice)
              IconButton(
                onPressed: () => _remove(id),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
