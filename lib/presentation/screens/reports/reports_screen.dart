import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/store/record_store.dart';
import '../../../core/services/report/report_pdf_service.dart';
import '../../../features/reports/report_calc.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/ui_kit.dart';
class ReportsScreen extends ConsumerStatefulWidget {
const ReportsScreen({super.key});
@override
ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}
class _ReportsScreenState extends ConsumerState<ReportsScreen> {
ReportPeriod _period = ReportPeriod.day;
DateTime _anchor = DateTime.now();
void _shift(int dir) {
setState(() {
switch (_period) {
case ReportPeriod.day:
_anchor = DateTime(_anchor.year, _anchor.month, _anchor.day + dir);
break;
case ReportPeriod.week:
_anchor = DateTime(_anchor.year, _anchor.month, _anchor.day + 7 * dir);
break;
case ReportPeriod.month:
_anchor = DateTime(_anchor.year, _anchor.month + dir, 1);
break;
}
});
}
String _rangeLabel(ReportData d) {
switch (_period) {
case ReportPeriod.day:
return '${dayName(d.start.weekday)}, ${fmtDate(d.start)}';
case ReportPeriod.week:
final last = DateTime(d.end.year, d.end.month, d.end.day - 1);
return '${fmtDate(d.start)} - ${fmtDate(last)}';
case ReportPeriod.month:
return '${monthName(d.start.month)} ${d.start.year}';
}
}
int _expensesIn(List<Rec> expenses, DateTime start, DateTime end) {
var sum = 0;
for (final e in expenses) {
final at = parseLocal('${e['date'] ?? ''}');
if (at == null) continue;
if (!at.isBefore(start) && at.isBefore(end)) sum += ni(e, 'amount');
}
return sum;
}
Future<void> _copy(ReportData d, int expenses) async {
final title = _period == ReportPeriod.day
? 'Daily Report'
: _period == ReportPeriod.week
? 'Weekly Report'
: 'Monthly Report';
final buf = StringBuffer()
..writeln('*${tr(title)}* - ${_rangeLabel(d)}')
..writeln('${tr('Revenue')}: ${rp(d.revenue)}')
..writeln('${tr('Transactions')}: ${d.count}')
..writeln('${tr('Items Sold')}: ${d.items}')
..writeln('${tr('Expenses')}: ${rp(expenses)}')
..writeln('${tr('Estimated Net')}: ${rp(d.revenue - expenses)}');
if (d.top.isNotEmpty) {
buf.writeln('${tr('Top Products')}:');
for (final p in d.top) {
buf.writeln('- ${p.name} x${p.qty}');
}
}
await Clipboard.setData(ClipboardData(text: buf.toString()));
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Summary copied')),
);
}
Future<void> _sharePdf(ReportData d, int expenses) async {
final title = _period == ReportPeriod.day
? 'Laporan Harian'
: _period == ReportPeriod.week
? 'Laporan Mingguan'
: 'Laporan Bulanan';
try {
final file = await ReportPdfService.salesReport(
data: d,
title: title,
rangeLabel: _rangeLabel(d),
expenses: expenses,
);
await ReportPdfService.share(file, text: '$title - ${_rangeLabel(d)}');
} catch (e) {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
}
}

@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
final data = ref.watch(reportDataProvider);
final expenses = ref.watch(expensesProvider);
return Scaffold(
appBar: AppBar(
title: const Text('Reports'),
actions: [
IconButton(
tooltip: 'Refresh',
icon: const Icon(Icons.refresh_rounded),
onPressed: () => ref.invalidate(reportDataProvider),
),
],
),
body: data.when(
loading: () => const Center(child: CircularProgressIndicator()),
error: (e, _) => Center(child: Text('Failed to load data')),
data: (all) {
final d = buildReport(all, _period, _anchor);
final exp = _expensesIn(expenses, d.start, d.end);
final growth = d.prevRevenue > 0 ? ((d.revenue - d.prevRevenue) * 100 / d.prevRevenue) : null;
final isUp = (growth ?? 0) >= 0;
final total = d.cash + d.bank;
return RefreshIndicator(
onRefresh: () async => ref.invalidate(reportDataProvider),
child: ListView(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
children: [
SegmentedButton<ReportPeriod>(
showSelectedIcon: false,
segments: const [
ButtonSegment(value: ReportPeriod.day, label: Text('Daily')),
ButtonSegment(value: ReportPeriod.week, label: Text('Weekly')),
ButtonSegment(value: ReportPeriod.month, label: Text('Monthly')),
],
selected: {_period},
onSelectionChanged: (s) => setState(() {
_period = s.first;
_anchor = DateTime.now();
}),
),
const SizedBox(height: 12),
Row(
children: [
IconButton.filledTonal(
onPressed: () => _shift(-1),
icon: const Icon(Icons.chevron_left_rounded),
),
Expanded(
child: Column(
children: [
Text(
_rangeLabel(d),
style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
),
TextButton(
onPressed: () => setState(() => _anchor = DateTime.now()),
child: const Text('Today'),
),
],
),
),
IconButton.filledTonal(
onPressed: () => _shift(1),
icon: const Icon(Icons.chevron_right_rounded),
),
],
),
const SizedBox(height: 8),
Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(24),
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [cs.primary, cs.tertiary],
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Text('Revenue', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
const Spacer(),
IconButton(
tooltip: 'Bagikan PDF (WhatsApp, dll)',
onPressed: () => _sharePdf(d, exp),
icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
),
IconButton(
tooltip: 'Copy summary',
onPressed: () => _copy(d, exp),
icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
),
],
),
Text(
rp(d.revenue),
style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
),
const SizedBox(height: 10),
if (growth != null)
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.22),
borderRadius: BorderRadius.circular(20),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
color: Colors.white,
size: 16,
),
const SizedBox(width: 6),
Text(
'${isUp ? '+' : ''}${growth.toStringAsFixed(1)}%  ${tr('vs previous period')}',
style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
),
],
),
)
else
const Text('No comparison data', style: TextStyle(color: Colors.white70, fontSize: 12)),
],
),
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: StatCard(
icon: Icons.receipt_long_rounded,
label: tr('Transactions'),
value: '${d.count}',
color: Colors.blue,
),
),
const SizedBox(width: 12),
Expanded(
child: StatCard(
icon: Icons.shopping_bag_rounded,
label: tr('Items Sold'),
value: '${d.items}',
color: Colors.purple,
),
),
],
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: StatCard(
icon: Icons.payments_rounded,
label: tr('Avg. per Transaction'),
value: rp(d.avg),
color: Colors.teal,
),
),
const SizedBox(width: 12),
Expanded(
child: StatCard(
icon: Icons.outbox_rounded,
label: tr('Expenses'),
value: rp(exp),
color: Colors.redAccent,
),
),
],
),
const SizedBox(height: 12),
SectionCard(
child: Row(
children: [
IconBadge(
icon: Icons.account_balance_wallet_rounded,
color: d.revenue - exp >= 0 ? Colors.green : Colors.red,
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('Estimated Net', style: TextStyle(fontWeight: FontWeight.w700)),
Text(
'Revenue - Expenses',
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
),
],
),
),
Text(
rp(d.revenue - exp),
style: TextStyle(
fontWeight: FontWeight.w900,
fontSize: 16,
color: d.revenue - exp >= 0 ? Colors.green : Colors.red,
),
),
],
),
),
const SizedBox(height: 12),
SectionCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SectionTitle('Sales Chart'),
BarChart(values: d.bars, labels: d.labels, labelEvery: d.labelEvery),
],
),
),
const SizedBox(height: 12),
SectionCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SectionTitle('Payment Method'),
if (total == 0)
const Text('No data')
else ...[
ClipRRect(
borderRadius: BorderRadius.circular(8),
child: Row(
children: [
Expanded(
flex: (d.cash * 100 / total).round().clamp(1, 99).toInt(),
child: Container(height: 14, color: cs.primary),
),
Expanded(
flex: (d.bank * 100 / total).round().clamp(1, 99).toInt(),
child: Container(height: 14, color: cs.tertiary),
),
],
),
),
const SizedBox(height: 12),
_Legend(color: cs.primary, label: tr('Cash'), value: rp(d.cash)),
const SizedBox(height: 6),
_Legend(color: cs.tertiary, label: tr('Bank'), value: rp(d.bank)),
],
],
),
),
const SizedBox(height: 12),
SectionCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SectionTitle('Top Products'),
if (d.top.isEmpty)
const Text('No data')
else
for (var i = 0; i < d.top.length; i++)
Padding(
padding: const EdgeInsets.symmetric(vertical: 6),
child: Row(
children: [
CircleAvatar(
radius: 13,
backgroundColor: cs.primaryContainer,
child: Text(
'${i + 1}',
style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
),
),
const SizedBox(width: 12),
Expanded(
child: Text(
d.top[i].name,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(fontWeight: FontWeight.w600),
),
),
Text('${d.top[i].qty} x', style: TextStyle(color: cs.outline)),
const SizedBox(width: 10),
Text(rp(d.top[i].revenue), style: const TextStyle(fontWeight: FontWeight.w700)),
],
),
),
],
),
),
],
),
);
},
),
);
}
}
class _Legend extends StatelessWidget {
const _Legend({required this.color, required this.label, required this.value});
final Color color;
final String label;
final String value;
@override
Widget build(BuildContext context) {
return Row(
children: [
Container(
width: 12,
height: 12,
decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
),
const SizedBox(width: 8),
Expanded(child: Text(label)),
Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
],
);
}
}
