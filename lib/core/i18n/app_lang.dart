import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/di/app_providers.dart';
import 'i18n_dict.dart';
const String _kLangKey = 'app_language';
class AppLang {
AppLang._();
static String current = 'id';
static final ValueNotifier<String> notifier = ValueNotifier<String>('id');
static bool get isId => current == 'id';
static void set(String code) {
current = code;
notifier.value = code;
}
}
final languageProvider = NotifierProvider<LanguageNotifier, String>(
LanguageNotifier.new,
);
class LanguageNotifier extends Notifier<String> {
@override
String build() {
final prefs = ref.watch(sharedPreferencesProvider);
final saved = prefs.getString(_kLangKey) ?? 'id';
AppLang.current = saved;
AppLang.notifier.value = saved;
return saved;
}
Future<void> setLanguage(String code) async {
AppLang.set(code);
state = code;
await ref.read(sharedPreferencesProvider).setString(_kLangKey, code);
}
}
/// Terjemahkan teks Inggris ke Indonesia jika bahasa = Indonesia.
String tr(String s) {
if (AppLang.current != 'id') return s;
final direct = kIdDict[s];
if (direct != null) return direct;
final i = s.indexOf(': ');
if (i > 0) {
final left = kIdDict[s.substring(0, i)];
if (left != null) return '$left: ${s.substring(i + 2)}';
}
return s;
}
const List<String> _monthsId = [
'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const List<String> _monthsEn = [
'January', 'February', 'March', 'April', 'May', 'June',
'July', 'August', 'September', 'October', 'November', 'December',
];
const List<String> _daysId = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const List<String> _daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
String monthName(int month, {bool short = false}) {
final n = (AppLang.isId ? _monthsId : _monthsEn)[(month - 1) % 12];
return short && n.length > 3 ? n.substring(0, 3) : n;
}
String dayName(int weekday, {bool short = false}) {
final n = (AppLang.isId ? _daysId : _daysEn)[(weekday - 1) % 7];
return short ? n.substring(0, 3) : n;
}
String two(int n) => n.toString().padLeft(2, '0');
String ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
String fmtDate(DateTime d) => '${d.day} ${monthName(d.month, short: true)} ${d.year}';
String fmtTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String fmtDateTime(DateTime d) => '${fmtDate(d)} • ${fmtTime(d)}';
int parseInt(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
