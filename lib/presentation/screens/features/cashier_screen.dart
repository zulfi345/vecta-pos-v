import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/store/record_store.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../features/reports/report_calc.dart';
import '../../widgets/ui_kit.dart';
class CashierScreen extends ConsumerStatefulWidget {
const CashierScreen({super.key});
@override
ConsumerState<CashierScreen> createState() => _CashierScreenState();
}
class _CashierScreenState extends ConsumerState<CashierScreen> {
final _opening = TextEditingController();
final _cashOut = TextEditingController();
final _actual = TextEditingController();
@override
void dispose() {
_opening.dispose();
_cashOut.dispose();
_actual.dispose();
super.dispose();
}
int _cashSales(Rec shift, List<TransactionEntity> tx) {
final from = DateTime.tryParse('${shift['openedAt'] ?? ''}');
if (from == null) return 0;
var sum = 0;
for (final t in tx) {
final at = parseLocal(t.createdAt);
if (at != null && !at.isBefore(from) && t.paymentMethod == 'cash') sum += t.totalAmount;
}
return sum;
}
Future<void> _open() async {
await ref.read(shiftsProvider.notifier).upsert({
'status': 'open',
'openedAt': DateTime.now().toIso8601String(),
'opening': parseInt(_opening.text),
'cashOut': 0,
});
_opening.clear();
}
Future<void> _addCashOut(Rec shift) async {
final v = parseInt(_cashOut.text);
if (v <= 0) return;
final rec = <String, dynamic>{...shift};
rec['cashOut'] = ni(shift, 'cashOut') + v;
await ref.read(shiftsProvider.notifier).upsert(rec);
_cashOut.clear();
}
Future<void> _close(Rec shift, int cashSales) async {
final expected = ni(shift, 'opening') + cashSales - ni(shift, 'cashOut');
final actual = parseInt(_actual.text);
final rec = <String, dynamic>{...shift};
rec['status'] = 'closed';
rec['closedAt'] = DateTime.now().toIso8601String();
rec['cashSales'] = cashSales;
rec['expected'] = expected;
rec['actual'] = actual;
await ref.read(shiftsProvider.notifier).upsert(rec);
_actual.clear();
}
@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
final shifts = ref.watch(shiftsProvider);
final txs = ref.watch(reportDataProvider).value ?? <TransactionEntity>[];
Rec? cur;
for (final s in shifts) {
if (s['status'] == 'open') {
cur = s;
break;
}
}
final closed = shifts.where((s) => s['status'] == 'closed').toList();
return Scaffold(
appBar: AppBar(title: const Text('Cashier Shift')),
body: ListView(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
children: [
if (cur == null)
SectionCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
IconBadge(icon: Icons.point_of_sale_rounded, color: Colors.green),
const SizedBox(width: 12),
const Expanded(
child: Text('Start Shift', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
),
],
),
const SizedBox(height: 14),
TextField(
controller: _opening,
keyboardType: TextInputType.number,
decoration: fieldDeco(context, tr('Opening Cash'), prefix: 'Rp '),
),
const SizedBox(height: 14),
PrimaryButton(label: 'Open Cashier', onTap: _open, icon: Icons.lock_open_rounded),
],
),
)
else
Builder(builder: (context) {
final shift = cur!;
final cashSales = _cashSales(shift, txs);
final expected = ni(shift, 'opening') + cashSales - ni(shift, 'cashOut');
final opened = DateTime.tryParse('${shift['openedAt']}');
return Column(
children: [
Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(24),
gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
opened == null ? '' : '${tr('Shift open since')} ${fmtDateTime(opened)}',
style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
),
const SizedBox(height: 6),
const Text('Expected Cash in Drawer', style: TextStyle(color: Colors.white70)),
Text(
rp(expected),
style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
),
],
),
),
const SizedBox(height: 12),
SectionCard(
child: Column(
children: [
_Row(label: tr('Opening Cash'), value: rp(ni(shift, 'opening'))),
_Row(label: tr('Cash Sales'), value: rp(cashSales)),
_Row(label: tr('Cash Out'), value: '- ${rp(ni(shift, 'cashOut'))}'),
],
),
),
const SizedBox(height: 12),
SectionCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SectionTitle('Cash Out'),
Row(
children: [
Expanded(
child: TextField(
controller: _cashOut,
keyboardType: TextInputType.number,
decoration: fieldDeco(context, tr('Amount'), prefix: 'Rp '),
),
),
const SizedBox(width: 10),
FilledButton.tonal(onPressed: () => _addCashOut(shift), child: const Text('Add')),
],
),
],
),
),
const SizedBox(height: 12),
SectionCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SectionTitle('Close Shift'),
TextField(
controller: _actual,
keyboardType: TextInputType.number,
decoration: fieldDeco(context, tr('Actual Cash Counted'), prefix: 'Rp '),
),
const SizedBox(height: 14),
PrimaryButton(
label: 'Close Cashier',
onTap: () => _close(shift, cashSales),
icon: Icons.lock_rounded,
),
],
),
),
],
);
}),
const SizedBox(height: 16),
const SectionTitle('Shift History'),
if (closed.isEmpty)
const EmptyHint(icon: Icons.history_rounded, text: 'Nothing to show')
else
for (final s in closed.take(30))
Padding(
padding: const EdgeInsets.only(bottom: 10),
child: SectionCard(
child: Builder(builder: (context) {
final diff = ni(s, 'actual') - ni(s, 'expected');
final at = DateTime.tryParse('${s['closedAt']}');
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(at == null ? '' : fmtDateTime(at), style: const TextStyle(fontWeight: FontWeight.w800)),
const SizedBox(height: 8),
_Row(label: tr('Expected Cash in Drawer'), value: rp(ni(s, 'expected'))),
_Row(label: tr('Actual Cash Counted'), value: rp(ni(s, 'actual'))),
_Row(
label: tr('Difference'),
value: '${diff > 0 ? '+' : ''}${rp(diff)}',
color: diff == 0 ? Colors.green : Colors.red,
),
],
);
}),
),
),
],
),
);
}
}
class _Row extends StatelessWidget {
const _Row({required this.label, required this.value, this.color});
final String label;
final String value;
final Color? color;
@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 4),
child: Row(
children: [
Expanded(child: Text(label)),
Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
],
),
);
}
}
