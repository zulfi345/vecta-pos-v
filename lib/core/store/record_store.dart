import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/app_providers.dart';
import '../../presentation/providers/auth/auth_notifier.dart';

typedef Rec = Map<String, dynamic>;

int ni(Rec r, String k) {
  final v = r[k];

  if (v is num) return v.toInt();

  return int.tryParse('${v ?? ''}') ?? 0;
}

class RecordList extends Notifier<List<Rec>> {
  RecordList(this.storeKey);

  final String storeKey;

  String? _userId;

  @override
  List<Rec> build() {
    _userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));

    final userId = _userId;

    if (userId != null) _load(userId);

    return <Rec>[];
  }

  Future<void> _load(String userId) async {
    await _importLegacy(userId);

    final res = await ref.read(recordLocalDatasourceProvider).getRecords(userId, storeKey);

    if (_userId != userId) return;

    state = res.data ?? <Rec>[];
  }

  Future<void> _importLegacy(String userId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'rec_$storeKey';
    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) return;

    try {
      final list = jsonDecode(raw) as List;
      final datasource = ref.read(recordLocalDatasourceProvider);

      for (final item in list.reversed) {
        final res = await datasource.upsertRecord(userId, storeKey, Map<String, dynamic>.from(item as Map));

        if (res.isFailure) return;
      }

      await prefs.remove(key);
    } catch (_) {
      return;
    }
  }

  Future<void> upsert(Rec r) async {
    final id = (r['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString();
    r['id'] = id;

    final index = state.indexWhere((e) => e['id'] == id);

    if (index >= 0) {
      final copy = [...state];
      copy[index] = r;
      state = copy;
    } else {
      state = [r, ...state];
    }

    final userId = _userId;

    if (userId == null) return;

    await ref.read(recordLocalDatasourceProvider).upsertRecord(userId, storeKey, r);
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e['id'] != id).toList();

    final userId = _userId;

    if (userId == null) return;

    await ref.read(recordLocalDatasourceProvider).deleteRecord(userId, storeKey, id);
  }
}

final employeesProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('employees'));
final attendanceProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('attendance'));
final expensesProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('expenses'));
final hppProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('hpp'));
final shiftsProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('shifts'));
