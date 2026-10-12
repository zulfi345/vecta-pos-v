import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/i18n/tr_text.dart';
import '../../widgets/ui_kit.dart';

/// Kelola akses login karyawan (ID + PIN) yang tersimpan di Supabase.
/// Khusus HP owner: semua aksi lewat fungsi `owner_manage`.
class StaffAccessScreen extends ConsumerStatefulWidget {
  const StaffAccessScreen({super.key});

  @override
  ConsumerState<StaffAccessScreen> createState() => _StaffAccessScreenState();
}

class _StaffAccessScreenState extends ConsumerState<StaffAccessScreen> {
  bool _loading = true;
  String? _error;
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
    final res = await account.manage('list_employees');
    if (!mounted) return;
    if (res['status'] == 'ok') {
      final raw = (res['items'] as List?) ?? const [];
      setState(() {
        _items = [for (final e in raw) Map<String, dynamic>.from(e as Map)];
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Gagal memuat data karyawan.';
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

  Future<void> _run(String action, Map<String, dynamic> data, String okMsg) async {
    final account = ref.read(accountServiceProvider);
    final res = await account.manage(action, data);
    if (!mounted) return;
    if (res['status'] == 'ok') {
      _toast(okMsg);
      await _load();
    } else {
      _toast(res['message']?.toString() ?? 'Gagal.', error: true);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ya')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _openAddForm() async {
    final account = ref.read(accountServiceProvider);
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _AddStaffForm(
        onSubmit: (code, name, pin) => account.manage('add_employee', {'code': code, 'name': name, 'pin': pin}),
      ),
    );
    if (added == true) {
      _toast('Karyawan ditambahkan.');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akses Karyawan (PIN)'),
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah'),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    SectionCard(
                      child: Row(
                        children: [
                          const IconBadge(icon: Icons.pin_rounded, color: Colors.indigo),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Karyawan masuk memakai email owner dan PIN. Satu PIN hanya untuk satu HP.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_items.isEmpty)
                      const EmptyHint(icon: Icons.badge_rounded, text: 'Belum ada karyawan')
                    else
                      for (final e in _items) _tile(context, e),
                  ],
                ),
    );
  }

  Widget _tile(BuildContext context, Map<String, dynamic> e) {
    final cs = Theme.of(context).colorScheme;
    final id = '${e['id']}';
    final active = e['active'] == true;
    final linked = e['linked'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            IconBadge(icon: Icons.badge_rounded, color: active ? Colors.indigo : Colors.grey),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    [
                      'ID: ${e['code'] ?? ''}',
                      active ? 'Aktif' : 'Nonaktif',
                      if (linked) 'HP terhubung',
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'release') {
                  if (await _confirm('Lepas HP', 'HP karyawan ini akan dilepas. Karyawan harus masuk lagi.')) {
                    await _run('release_employee', {'id': id}, 'HP dilepas.');
                  }
                } else if (v == 'deactivate') {
                  if (await _confirm('Nonaktifkan', 'Karyawan tidak bisa masuk lagi sampai diaktifkan.')) {
                    await _run('set_employee_active', {'id': id, 'active': 'false'}, 'Karyawan dinonaktifkan.');
                  }
                } else if (v == 'activate') {
                  await _run('set_employee_active', {'id': id, 'active': 'true'}, 'Karyawan diaktifkan.');
                }
              },
              itemBuilder: (_) => [
                if (linked) const PopupMenuItem(value: 'release', child: Text('Lepas HP')),
                if (active)
                  const PopupMenuItem(value: 'deactivate', child: Text('Nonaktifkan'))
                else
                  const PopupMenuItem(value: 'activate', child: Text('Aktifkan')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStaffForm extends StatefulWidget {
  const _AddStaffForm({required this.onSubmit});

  final Future<Map<String, dynamic>> Function(String code, String name, String pin) onSubmit;

  @override
  State<_AddStaffForm> createState() => _AddStaffFormState();
}

class _AddStaffFormState extends State<_AddStaffForm> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _code.text.trim();
    final name = _name.text.trim();
    final pin = _pin.text.trim();
    if (code.isEmpty || name.isEmpty) {
      setState(() => _err = 'ID karyawan dan nama wajib diisi.');
      return;
    }
    if (!RegExp(r'^[0-9]{4,8}$').hasMatch(pin)) {
      setState(() => _err = 'PIN harus 4 sampai 8 angka.');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    final res = await widget.onSubmit(code, name, pin);
    if (!mounted) return;
    if (res['status'] == 'ok') {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _err = res['message']?.toString() ?? 'Gagal menambah karyawan.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tambah Karyawan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(controller: _code, decoration: fieldDeco(context, 'ID Karyawan (contoh: K01)')),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: fieldDeco(context, 'Nama')),
            const SizedBox(height: 12),
            TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              decoration: fieldDeco(context, 'PIN (4-8 angka)'),
            ),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 14),
            PrimaryButton(label: _busy ? 'Menyimpan...' : 'Simpan', onTap: _busy ? null : _save, icon: Icons.check_rounded),
          ],
        ),
      ),
    );
  }
}
