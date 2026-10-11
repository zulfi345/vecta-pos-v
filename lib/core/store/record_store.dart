import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/di/app_providers.dart';
typedef Rec = Map<String, dynamic>;
int ni(Rec r, String k) {
final v = r[k];
if (v is num) return v.toInt();
return int.tryParse('${v ?? ''}') ?? 0;
}
class RecordList extends Notifier<List<Rec>> {
RecordList(this.storeKey);
final String storeKey;
@override
List<Rec> build() {
final raw = ref.watch(sharedPreferencesProvider).getString('rec_$storeKey');
if (raw == null || raw.isEmpty) return <Rec>[];
try {
final list = jsonDecode(raw) as List;
return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
} catch (_) {
return <Rec>[];
}
}
Future<void> _persist() async {
await ref.read(sharedPreferencesProvider).setString('rec_$storeKey', jsonEncode(state));
}
Future<void> upsert(Rec r) async {
final id = (r['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString();
r['id'] = id;
final i = state.indexWhere((e) => e['id'] == id);
if (i >= 0) {
final c = [...state];
c[i] = r;
state = c;
} else {
state = [r, ...state];
}
await _persist();
}
Future<void> remove(String id) async {
state = state.where((e) => e['id'] != id).toList();
await _persist();
}
}
final employeesProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('employees'));
final attendanceProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('attendance'));
final expensesProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('expenses'));
final hppProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('hpp'));
final shiftsProvider = NotifierProvider<RecordList, List<Rec>>(() => RecordList('shifts'));
