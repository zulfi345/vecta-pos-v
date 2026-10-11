import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/store/record_store.dart';
import '../../widgets/ui_kit.dart';
class _Ing {
_Ing({String name = '', String cost = ''})
: name = TextEditingController(text: name),
cost = TextEditingController(text: cost);
final TextEditingController name;
final TextEditingController cost;
void dispose() {
name.dispose();
cost.dispose();
}
}
class HppScreen extends ConsumerStatefulWidget {
const HppScreen({super.key});
@override
ConsumerState<HppScreen> createState() => _HppScreenState();
}
class _HppScreenState extends ConsumerState<HppScreen> {
final _name = TextEditingController();
final _yield = TextEditingController(text: '1');
final _other = TextEditingController();
final _margin = TextEditingController(text: '30');
List<_Ing> _ings = [_Ing()];
String? _editId;
@override
void dispose() {
_name.dispose();
_yield.dispose();
_other.dispose();
_margin.dispose();
for (final i in _ings) {
i.dispose();
}
super.dispose();
}
int get _ingTotal {
var sum = 0;
for (final i in _ings) {
sum += parseInt(i.cost.text);
}
return sum;
}
int get _totalCost => _ingTotal + parseInt(_other.text);
double get _hpp {
final y = parseInt(_yield.text);
return y <= 0 ? 0 : _totalCost / y;
}
double get _price => _hpp * (1 + (int.tryParse(_margin.text.trim()) ?? 0) / 100);
void _reset() {
setState(() {
_editId = null;
_name.clear();
_yield.text = '1';
_other.clear();
_margin.text = '30';
for (final i in _ings) {
i.dispose();
}
_ings = [_Ing()];
});
}
void _load(Rec r) {
setState(() {
_editId = '${r['id']}';
_name.text = '${r['name'] ?? ''}';
_yield.text = '${ni(r, 'yield')}';
_other.text = ni(r, 'other') == 0 ? '' : '${ni(r, 'other')}';
_margin.text = '${ni(r, 'margin')}';
for (final i in _ings) {
i.dispose();
}
final list = (r['ings'] as List?) ?? const [];
_ings = list.isEmpty
? [_Ing()]
: list.map((e) {
final m = Map<String, dynamic>.from(e as Map);
return _Ing(name: '${m['n'] ?? ''}', cost: '${m['c'] ?? ''}');
}).toList();
});
}
Future<void> _save() async {
final name = _name.text.trim();
if (name.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product name is required')));
return;
}
await ref.read(hppProvider.notifier).upsert({
if (_editId != null) 'id': _editId,
'name': name,
'yield': parseInt(_yield.text),
'other': parseInt(_other.text),
'margin': int.tryParse(_margin.text.trim()) ?? 0,
'ings': _ings.map((i) => {'n': i.name.text.trim(), 'c': parseInt(i.cost.text)}).toList(),
'hpp': _hpp.round(),
'price': _price.round(),
});
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved')));
_reset();
}
@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
final saved = ref.watch(hppProvider);
return Scaffold(
appBar: AppBar(
title: const Text('Cost of Goods (HPP)'),
actions: [
IconButton(tooltip: 'Reset', onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded)),
],
),
body: ListView(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
children: [
Container(
width: double.infinity,
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
const Text('HPP per Unit', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
Text(
rp(_hpp.round()),
style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
),
const SizedBox(height: 10),
Row(
children: [
Expanded(
child: _Mini(label: tr('Suggested Price'), value: rp(_price.round())),
),
const SizedBox(width: 10),
Expanded(
child: _Mini(label: tr('Profit per Unit'), value: rp((_price - _hpp).round())),
),
],
),
],
),
),
const SizedBox(height: 14),
SectionCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SectionTitle('Product'),
TextField(
controller: _name,
decoration: fieldDeco(context, tr('Product Name')),
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: TextField(
controller: _yield,
keyboardType: TextInputType.number,
onChanged: (_) => setState(() {}),
decoration: fieldDeco(context, tr('Units Produced')),
),
),
const SizedBox(width: 10),
Expanded(
child: TextField(
controller: _margin,
keyboardType: TextInputType.number,
onChanged: (_) => setState(() {}),
decoration: fieldDeco(context, tr('Margin %')),
),
),
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
Row(
children: [
const Expanded(child: SectionTitle('Ingredients / Materials')),
TextButton.icon(
onPressed: () => setState(() => _ings.add(_Ing())),
icon: const Icon(Icons.add_rounded, size: 18),
label: const Text('Add'),
),
],
),
for (var i = 0; i < _ings.length; i++)
Padding(
padding: const EdgeInsets.only(bottom: 10),
child: Row(
children: [
Expanded(
flex: 5,
child: TextField(
controller: _ings[i].name,
decoration: fieldDeco(context, tr('Name')),
),
),
const SizedBox(width: 8),
Expanded(
flex: 4,
child: TextField(
controller: _ings[i].cost,
keyboardType: TextInputType.number,
onChanged: (_) => setState(() {}),
decoration: fieldDeco(context, tr('Cost'), prefix: 'Rp '),
),
),
IconButton(
onPressed: _ings.length <= 1
? null
: () => setState(() {
_ings[i].dispose();
_ings.removeAt(i);
}),
icon: const Icon(Icons.close_rounded),
),
],
),
),
TextField(
controller: _other,
keyboardType: TextInputType.number,
onChanged: (_) => setState(() {}),
decoration: fieldDeco(context, tr('Other Costs (labor, packaging, gas)'), prefix: 'Rp '),
),
const SizedBox(height: 12),
Row(
children: [
const Expanded(child: Text('Total Cost')),
Text(rp(_totalCost), style: const TextStyle(fontWeight: FontWeight.w900)),
],
),
],
),
),
const SizedBox(height: 14),
PrimaryButton(label: 'Save Calculation', onTap: _save, icon: Icons.save_rounded),
const SizedBox(height: 20),
const SectionTitle('Saved Calculations'),
if (saved.isEmpty)
const EmptyHint(icon: Icons.calculate_rounded, text: 'Nothing to show')
else
for (final r in saved)
Padding(
padding: const EdgeInsets.only(bottom: 10),
child: SectionCard(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
child: InkWell(
onTap: () => _load(r),
child: Row(
children: [
IconBadge(icon: Icons.calculate_rounded, color: Colors.deepOrange),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('${r['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
Text(
'HPP ${rp(ni(r, 'hpp'))}  •  ${tr('Price')} ${rp(ni(r, 'price'))}',
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
),
],
),
),
IconButton(
onPressed: () => ref.read(hppProvider.notifier).remove('${r['id']}'),
icon: const Icon(Icons.delete_outline_rounded),
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
class _Mini extends StatelessWidget {
const _Mini({required this.label, required this.value});
final String label;
final String value;
@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.2),
borderRadius: BorderRadius.circular(16),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
],
),
);
}
}
