import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/store/record_store.dart';
import '../../widgets/ui_kit.dart';
class FieldSpec {
const FieldSpec(this.key, this.label, {this.number = false, this.required = false});
final String key;
final String label;
final bool number;
final bool required;
}
/// Layar CRUD generik (tambah / ubah / hapus) yang dipakai Karyawan & Pengeluaran.
class RecordsScreen extends ConsumerWidget {
const RecordsScreen({
super.key,
required this.title,
required this.provider,
required this.fields,
required this.titleOf,
required this.subtitleOf,
required this.icon,
required this.color,
this.trailingOf,
this.summaryOf,
this.autoDate = false,
});
final String title;
final NotifierProvider<RecordList, List<Rec>> provider;
final List<FieldSpec> fields;
final String Function(Rec) titleOf;
final String Function(Rec) subtitleOf;
final String Function(Rec)? trailingOf;
final String Function(List<Rec>)? summaryOf;
final IconData icon;
final Color color;
final bool autoDate;
void _openForm(BuildContext context, WidgetRef ref, Rec? existing) {
showModalBottomSheet<void>(
context: context,
isScrollControlled: true,
showDragHandle: true,
builder: (ctx) => _RecordForm(
title: title,
fields: fields,
existing: existing,
onSave: (rec) async {
if (autoDate) rec['date'] = existing?['date'] ?? DateTime.now().toIso8601String();
await ref.read(provider.notifier).upsert(rec);
if (ctx.mounted) Navigator.of(ctx).pop();
},
),
);
}
Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Rec r) async {
final ok = await showDialog<bool>(
context: context,
builder: (ctx) => AlertDialog(
title: const Text('Confirm'),
content: const Text('Are you sure want to delete this item?'),
actions: [
TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
],
),
);
if (ok == true) await ref.read(provider.notifier).remove('${r['id']}');
}
@override
Widget build(BuildContext context, WidgetRef ref) {
final cs = Theme.of(context).colorScheme;
final items = ref.watch(provider);
return Scaffold(
appBar: AppBar(title: Text(title)),
floatingActionButton: FloatingActionButton.extended(
onPressed: () => _openForm(context, ref, null),
icon: const Icon(Icons.add_rounded),
label: const Text('Add'),
),
body: ListView(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
children: [
if (summaryOf != null)
Padding(
padding: const EdgeInsets.only(bottom: 12),
child: SectionCard(
child: Row(
children: [
IconBadge(icon: icon, color: color),
const SizedBox(width: 14),
Expanded(child: Text(summaryOf!(items), style: const TextStyle(fontWeight: FontWeight.w800))),
],
),
),
),
if (items.isEmpty)
EmptyHint(icon: icon, text: tr('Nothing to show'))
else
for (final r in items)
Padding(
padding: const EdgeInsets.only(bottom: 10),
child: SectionCard(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
child: Row(
children: [
IconBadge(icon: icon, color: color),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(titleOf(r), style: const TextStyle(fontWeight: FontWeight.w700)),
if (subtitleOf(r).isNotEmpty)
Text(
subtitleOf(r),
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
),
],
),
),
if (trailingOf != null)
Text(trailingOf!(r), style: const TextStyle(fontWeight: FontWeight.w800)),
PopupMenuButton<String>(
onSelected: (v) {
if (v == 'edit') _openForm(context, ref, r);
if (v == 'delete') _confirmDelete(context, ref, r);
},
itemBuilder: (_) => [
PopupMenuItem(value: 'edit', child: Text('Edit')),
PopupMenuItem(value: 'delete', child: Text('Delete')),
],
),
],
),
),
),
],
),
);
}
}
class _RecordForm extends StatefulWidget {
const _RecordForm({
required this.title,
required this.fields,
required this.existing,
required this.onSave,
});
final String title;
final List<FieldSpec> fields;
final Rec? existing;
final Future<void> Function(Rec) onSave;
@override
State<_RecordForm> createState() => _RecordFormState();
}
class _RecordFormState extends State<_RecordForm> {
late final Map<String, TextEditingController> _c;
String? _err;
@override
void initState() {
super.initState();
_c = {
for (final f in widget.fields)
f.key: TextEditingController(text: widget.existing == null ? '' : '${widget.existing![f.key] ?? ''}'),
};
}
@override
void dispose() {
for (final c in _c.values) {
c.dispose();
}
super.dispose();
}
void _save() {
final rec = <String, dynamic>{...?widget.existing};
for (final f in widget.fields) {
final text = _c[f.key]!.text.trim();
if (f.required && text.isEmpty) {
setState(() => _err = '${tr(f.label)}: ${tr('is required')}');
return;
}
rec[f.key] = f.number ? parseInt(text) : text;
}
widget.onSave(rec);
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
Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
const SizedBox(height: 14),
for (final f in widget.fields)
Padding(
padding: const EdgeInsets.only(bottom: 12),
child: TextField(
controller: _c[f.key],
keyboardType: f.number ? TextInputType.number : TextInputType.text,
decoration: fieldDeco(context, tr(f.label), prefix: f.number ? 'Rp ' : null),
),
),
if (_err != null)
Padding(
padding: const EdgeInsets.only(bottom: 10),
child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
),
PrimaryButton(label: 'Save', onTap: _save, icon: Icons.check_rounded),
],
),
),
);
}
}
class EmployeesScreen extends StatelessWidget {
const EmployeesScreen({super.key});
@override
Widget build(BuildContext context) {
return RecordsScreen(
title: 'Employee Management',
provider: employeesProvider,
icon: Icons.badge_rounded,
color: Colors.indigo,
fields: const [
FieldSpec('name', 'Full Name', required: true),
FieldSpec('role', 'Role / Position'),
FieldSpec('phone', 'Phone Number'),
FieldSpec('wage', 'Daily Wage', number: true),
],
titleOf: (r) => '${r['name'] ?? ''}',
subtitleOf: (r) => [
if ('${r['role'] ?? ''}'.isNotEmpty) '${r['role']}',
if ('${r['phone'] ?? ''}'.isNotEmpty) '${r['phone']}',
].join(' • '),
trailingOf: (r) => ni(r, 'wage') > 0 ? '${rp(ni(r, 'wage'))}${tr('/day')}' : '',
summaryOf: (l) => '${l.length} ${tr('employees')}',
);
}
}
class ExpensesScreen extends StatelessWidget {
const ExpensesScreen({super.key});
@override
Widget build(BuildContext context) {
return RecordsScreen(
title: 'Expenses',
provider: expensesProvider,
icon: Icons.outbox_rounded,
color: Colors.redAccent,
autoDate: true,
fields: const [
FieldSpec('title', 'Expense Name', required: true),
FieldSpec('amount', 'Amount', number: true, required: true),
FieldSpec('note', 'Note (Optional)'),
],
titleOf: (r) => '${r['title'] ?? ''}',
subtitleOf: (r) {
final at = DateTime.tryParse('${r['date'] ?? ''}');
final note = '${r['note'] ?? ''}';
return [if (at != null) fmtDateTime(at.toLocal()), if (note.isNotEmpty) note].join(' • ');
},
trailingOf: (r) => rp(ni(r, 'amount')),
summaryOf: (l) {
final now = DateTime.now();
var sum = 0;
for (final r in l) {
final at = DateTime.tryParse('${r['date'] ?? ''}')?.toLocal();
if (at != null && at.year == now.year && at.month == now.month) sum += ni(r, 'amount');
}
return '${tr('This month')}: ${rp(sum)}';
},
);
}
}
