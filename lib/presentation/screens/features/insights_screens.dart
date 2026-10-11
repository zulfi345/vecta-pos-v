import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../features/reports/report_calc.dart';
import '../../widgets/ui_kit.dart';
class LowStockScreen extends ConsumerStatefulWidget {
const LowStockScreen({super.key});
@override
ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}
class _LowStockScreenState extends ConsumerState<LowStockScreen> {
int _limit = 10;
@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
final products = ref.watch(allProductsProvider);
return Scaffold(
appBar: AppBar(title: const Text('Low Stock')),
body: products.when(
loading: () => const Center(child: CircularProgressIndicator()),
error: (e, _) => const Center(child: Text('Failed to load data')),
data: (all) {
final low = all.where((p) => p.stock <= _limit).toList()..sort((a, b) => a.stock.compareTo(b.stock));
return ListView(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
children: [
SectionCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SectionTitle('Alert when stock is at or below'),
Wrap(
spacing: 8,
children: [
for (final v in const [5, 10, 20, 50])
ChoiceChip(
label: Text('$v'),
selected: _limit == v,
onSelected: (_) => setState(() => _limit = v),
),
],
),
],
),
),
const SizedBox(height: 12),
if (low.isEmpty)
const EmptyHint(icon: Icons.inventory_2_rounded, text: 'All stock is safe')
else
for (final p in low)
Padding(
padding: const EdgeInsets.only(bottom: 10),
child: SectionCard(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
child: Row(
children: [
IconBadge(
icon: p.stock <= 0 ? Icons.error_rounded : Icons.warning_amber_rounded,
color: p.stock <= 0 ? Colors.red : Colors.orange,
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
const SizedBox(height: 6),
ClipRRect(
borderRadius: BorderRadius.circular(6),
child: LinearProgressIndicator(
value: (p.stock / _limit).clamp(0.0, 1.0).toDouble(),
minHeight: 6,
color: p.stock <= 0 ? Colors.red : Colors.orange,
backgroundColor: cs.surfaceContainerHighest,
),
),
],
),
),
const SizedBox(width: 14),
Text(
p.stock <= 0 ? tr('Out of stock') : '${p.stock} ${tr('left')}',
style: TextStyle(
fontWeight: FontWeight.w800,
color: p.stock <= 0 ? Colors.red : Colors.orange,
),
),
],
),
),
),
],
);
},
),
);
}
}
class BestSellersScreen extends ConsumerStatefulWidget {
const BestSellersScreen({super.key});
@override
ConsumerState<BestSellersScreen> createState() => _BestSellersScreenState();
}
class _BestSellersScreenState extends ConsumerState<BestSellersScreen> {
int _days = 30;
@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
final data = ref.watch(reportDataProvider);
return Scaffold(
appBar: AppBar(title: const Text('Best Sellers')),
body: data.when(
loading: () => const Center(child: CircularProgressIndicator()),
error: (e, _) => const Center(child: Text('Failed to load data')),
data: (all) {
final from = _days == 0 ? null : DateTime.now().subtract(Duration(days: _days));
final top = topProducts(all, from, limit: 20);
final maxQty = top.isEmpty ? 1 : top.first.qty;
return ListView(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
children: [
SegmentedButton<int>(
showSelectedIcon: false,
segments: const [
ButtonSegment(value: 7, label: Text('7 Days')),
ButtonSegment(value: 30, label: Text('30 Days')),
ButtonSegment(value: 0, label: Text('All Time')),
],
selected: {_days},
onSelectionChanged: (s) => setState(() => _days = s.first),
),
const SizedBox(height: 14),
if (top.isEmpty)
const EmptyHint(icon: Icons.emoji_events_rounded, text: 'No data')
else
for (var i = 0; i < top.length; i++)
Padding(
padding: const EdgeInsets.only(bottom: 10),
child: SectionCard(
padding: const EdgeInsets.all(14),
child: Column(
children: [
Row(
children: [
CircleAvatar(
radius: 15,
backgroundColor: i < 3 ? Colors.amber : cs.primaryContainer,
child: Text(
'${i + 1}',
style: TextStyle(
fontWeight: FontWeight.w900,
color: i < 3 ? Colors.black87 : cs.onPrimaryContainer,
),
),
),
const SizedBox(width: 12),
Expanded(
child: Text(
top[i].name,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(fontWeight: FontWeight.w700),
),
),
Text('${top[i].qty} ${tr('sold')}', style: const TextStyle(fontWeight: FontWeight.w800)),
],
),
const SizedBox(height: 10),
ClipRRect(
borderRadius: BorderRadius.circular(6),
child: LinearProgressIndicator(
value: (top[i].qty / maxQty).clamp(0.0, 1.0).toDouble(),
minHeight: 7,
backgroundColor: cs.surfaceContainerHighest,
),
),
const SizedBox(height: 6),
Align(
alignment: Alignment.centerRight,
child: Text(
rp(top[i].revenue),
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
),
),
],
),
),
),
],
);
},
),
);
}
}
