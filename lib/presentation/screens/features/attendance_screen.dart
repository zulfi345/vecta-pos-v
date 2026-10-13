import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/services/report/report_pdf_service.dart';
import '../../../core/store/record_store.dart';
import '../../widgets/ui_kit.dart';
class AttendanceScreen extends ConsumerWidget {
const AttendanceScreen({super.key});
Rec? _today(List<Rec> att, String empId, String day) {
for (final a in att) {
if (a['empId'] == empId && a['date'] == day) return a;
}
return null;
}
Future<bool> _verifyPin(BuildContext context, Rec emp) async {
final pin = '${emp['pin'] ?? ''}';
if (pin.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('PIN ${emp['name']} belum diatur. Atur di Employee Management.')),
);
return false;
}
final ctrl = TextEditingController();
final ok = await showDialog<bool>(
context: context,
builder: (ctx) {
String? err;
return StatefulBuilder(
builder: (ctx, setS) => AlertDialog(
title: Text('PIN ${emp['name']}'),
content: TextField(
controller: ctrl,
autofocus: true,
obscureText: true,
maxLength: 6,
keyboardType: TextInputType.number,
inputFormatters: [FilteringTextInputFormatter.digitsOnly],
decoration: InputDecoration(labelText: 'Masukkan PIN', errorText: err),
),
actions: [
TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
FilledButton(
onPressed: () {
if (ctrl.text == pin) {
Navigator.of(ctx).pop(true);
} else {
setS(() => err = 'PIN salah');
}
},
child: const Text('OK'),
),
],
),
);
},
);
ctrl.dispose();
return ok == true;
}

/// Ambil selfie (kamera depan) dan simpan permanen di folder aplikasi.
Future<String?> _takeSelfie() async {
try {
final shot = await ImagePicker().pickImage(
source: ImageSource.camera,
preferredCameraDevice: CameraDevice.front,
imageQuality: 40,
maxWidth: 720,
);
if (shot == null) return null;
final dir = await getApplicationDocumentsDirectory();
final folder = Directory(p.join(dir.path, 'attendance'));
if (!await folder.exists()) await folder.create(recursive: true);
final dest = p.join(folder.path, 'selfie_${DateTime.now().microsecondsSinceEpoch}.jpg');
await File(shot.path).copy(dest);
return dest;
} catch (_) {
return null;
}
}

Future<void> _mark(BuildContext context, WidgetRef ref, Rec emp, Rec? cur, String action) async {
final messenger = ScaffoldMessenger.of(context);
if (!await _verifyPin(context, emp)) return;
String? photo;
if (action != 'leave') {
photo = await _takeSelfie();
if (photo == null) {
messenger.showSnackBar(const SnackBar(content: Text('Selfie wajib untuk absen.')));
return;
}
}
final now = DateTime.now();
final rec = <String, dynamic>{...?cur};
rec['empId'] = emp['id'];
rec['empName'] = emp['name'];
rec['date'] = ymd(now);
if (action == 'in') {
rec['status'] = 'present';
rec['inAt'] = now.toIso8601String();
rec['inPhoto'] = photo;
} else if (action == 'out') {
rec['outAt'] = now.toIso8601String();
rec['outPhoto'] = photo;
} else {
rec['status'] = 'leave';
rec.remove('inAt');
rec.remove('outAt');
rec.remove('inPhoto');
rec.remove('outPhoto');
}
await ref.read(attendanceProvider.notifier).upsert(rec);
}

Future<void> _sharePdf(BuildContext context, WidgetRef ref) async {
final messenger = ScaffoldMessenger.of(context);
try {
final now = DateTime.now();
final file = await ReportPdfService.attendanceReport(
month: DateTime(now.year, now.month, 1),
employees: ref.read(employeesProvider),
attendance: ref.read(attendanceProvider),
);
await ReportPdfService.share(file, text: 'Rekap absensi ${now.month}/${now.year}');
} catch (e) {
messenger.showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
}
}

void _showPhotos(BuildContext context, Rec a) {
final paths = [
for (final k in ['inPhoto', 'outPhoto'])
if (a[k] != null && File('${a[k]}').existsSync()) MapEntry(k == 'inPhoto' ? 'Masuk' : 'Pulang', '${a[k]}'),
];
if (paths.isEmpty) return;
showDialog<void>(
context: context,
builder: (ctx) => AlertDialog(
title: Text('${a['empName']} • ${a['date']}'),
content: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
for (final e in paths) ...[
Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700)),
const SizedBox(height: 6),
ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(e.value))),
const SizedBox(height: 12),
],
],
),
),
actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tutup'))],
),
);
}

String _duration(Rec a) {
final i = DateTime.tryParse('${a['inAt'] ?? ''}');
final o = DateTime.tryParse('${a['outAt'] ?? ''}');
if (i == null || o == null) return '';
final m = o.difference(i).inMinutes;
return '${m ~/ 60}${tr('h')} ${m % 60}${tr('m')}';
}
@override
Widget build(BuildContext context, WidgetRef ref) {
final cs = Theme.of(context).colorScheme;
final emps = ref.watch(employeesProvider);
final att = ref.watch(attendanceProvider);
final now = DateTime.now();
final day = ymd(now);
final history = [...att]..sort((a, b) => '${b['date']}${b['inAt'] ?? ''}'.compareTo('${a['date']}${a['inAt'] ?? ''}'));
var present = 0;
for (final e in emps) {
final a = _today(att, '${e['id']}', day);
if (a != null && a['status'] == 'present') present++;
}
return Scaffold(
appBar: AppBar(
title: const Text('Attendance'),
actions: [
IconButton(
tooltip: 'Bagikan rekap PDF (WhatsApp, dll)',
onPressed: () => _sharePdf(context, ref),
icon: const Icon(Icons.picture_as_pdf_rounded),
),
],
),
body: ListView(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
children: [
SectionCard(
child: Row(
children: [
IconBadge(icon: Icons.event_available_rounded, color: Colors.green),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('${dayName(now.weekday)}, ${fmtDate(now)}', style: const TextStyle(fontWeight: FontWeight.w800)),
Text(
'${tr('Present')}: $present / ${emps.length}',
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
),
],
),
),
],
),
),
const SizedBox(height: 14),
const SectionTitle('Today'),
if (emps.isEmpty)
const EmptyHint(icon: Icons.badge_rounded, text: 'Add employees first in Employee Management')
else
for (final e in emps)
Builder(builder: (context) {
final a = _today(att, '${e['id']}', day);
final status = a == null ? '' : '${a['status']}';
final hasIn = a != null && a['inAt'] != null;
final hasOut = a != null && a['outAt'] != null;
return Padding(
padding: const EdgeInsets.only(bottom: 10),
child: SectionCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
CircleAvatar(
backgroundColor: cs.primaryContainer,
child: Text(
'${e['name'] ?? '?'}'.isEmpty ? '?' : '${e['name']}'.substring(0, 1).toUpperCase(),
style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('${e['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
Text(
status == 'present'
? '${tr('Present')}${hasIn ? ' • ${fmtTime(DateTime.parse('${a?['inAt']}'))}' : ''}${hasOut ? ' - ${fmtTime(DateTime.parse('${a?['outAt']}'))}' : ''}'
: status == 'leave'
? tr('On Leave / Sick')
: tr('Not checked in'),
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: status == 'present'
? Colors.green
: status == 'leave'
? Colors.orange
: cs.outline,
),
),
],
),
),
],
),
const SizedBox(height: 10),
Row(
children: [
Expanded(
child: FilledButton.tonalIcon(
onPressed: hasIn ? null : () => _mark(context, ref, e, a, 'in'),
icon: const Icon(Icons.login_rounded, size: 18),
label: const Text('Check In'),
),
),
const SizedBox(width: 8),
Expanded(
child: FilledButton.tonalIcon(
onPressed: (!hasIn || hasOut) ? null : () => _mark(context, ref, e, a, 'out'),
icon: const Icon(Icons.logout_rounded, size: 18),
label: const Text('Check Out'),
),
),
const SizedBox(width: 8),
IconButton.outlined(
tooltip: 'On Leave / Sick',
onPressed: hasIn ? null : () => _mark(context, ref, e, a, 'leave'),
icon: const Icon(Icons.healing_rounded, size: 18),
),
],
),
],
),
),
);
}),
const SizedBox(height: 14),
const SectionTitle('History'),
if (history.isEmpty)
const EmptyHint(icon: Icons.history_rounded, text: 'Nothing to show')
else
for (final a in history.take(40))
Padding(
padding: const EdgeInsets.only(bottom: 8),
child: InkWell(
onTap: () => _showPhotos(context, a),
child: SectionCard(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
child: Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('${a['empName']}', style: const TextStyle(fontWeight: FontWeight.w700)),
Text(
'${a['date']}',
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
),
],
),
),
Text(
a['status'] == 'leave' ? tr('On Leave / Sick') : _duration(a).isEmpty ? tr('Present') : _duration(a),
style: TextStyle(
fontWeight: FontWeight.w700,
color: a['status'] == 'leave' ? Colors.orange : Colors.green,
),
),
],
),
),
),
),
],
),
);
}
}
