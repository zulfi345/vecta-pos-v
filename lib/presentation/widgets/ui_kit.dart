import 'package:flutter/material.dart' hide Text;
import '../../core/i18n/tr_text.dart';
import '../../core/utilities/currency_formatter.dart';
String rp(num v) => CurrencyFormatter.format(v);
class SectionCard extends StatelessWidget {
const SectionCard({
super.key,
required this.child,
this.padding = const EdgeInsets.all(16),
this.color,
});
final Widget child;
final EdgeInsets padding;
final Color? color;
@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
return Container(
width: double.infinity,
padding: padding,
decoration: BoxDecoration(
color: color ?? cs.surface,
borderRadius: BorderRadius.circular(20),
border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
),
child: child,
);
}
}
class SectionTitle extends StatelessWidget {
const SectionTitle(this.text, {super.key});
final String text;
@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.only(bottom: 10),
child: Text(
text,
style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
),
);
}
}
class IconBadge extends StatelessWidget {
const IconBadge({super.key, required this.icon, required this.color, this.size = 40});
final IconData icon;
final Color color;
final double size;
@override
Widget build(BuildContext context) {
return Container(
width: size,
height: size,
decoration: BoxDecoration(
color: color.withValues(alpha: 0.14),
borderRadius: BorderRadius.circular(size * 0.34),
),
child: Icon(icon, color: color, size: size * 0.5),
);
}
}
class StatCard extends StatelessWidget {
const StatCard({
super.key,
required this.icon,
required this.label,
required this.value,
required this.color,
});
final IconData icon;
final String label;
final String value;
final Color color;
@override
Widget build(BuildContext context) {
final t = Theme.of(context).textTheme;
return SectionCard(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
IconBadge(icon: icon, color: color, size: 34),
const SizedBox(height: 12),
Text(
value,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
),
const SizedBox(height: 2),
Text(
label,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
),
],
),
);
}
}
class MenuTile extends StatelessWidget {
const MenuTile({
super.key,
required this.icon,
required this.title,
required this.color,
required this.onTap,
this.subtitle,
});
final IconData icon;
final String title;
final String? subtitle;
final Color color;
final VoidCallback onTap;
@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
return Padding(
padding: const EdgeInsets.only(bottom: 10),
child: Material(
color: cs.surface,
borderRadius: BorderRadius.circular(18),
child: InkWell(
borderRadius: BorderRadius.circular(18),
onTap: onTap,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(18),
border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
),
child: Row(
children: [
IconBadge(icon: icon, color: color),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
if (subtitle != null)
Text(
subtitle!,
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
),
],
),
),
Icon(Icons.chevron_right_rounded, color: cs.outline),
],
),
),
),
),
);
}
}
class EmptyHint extends StatelessWidget {
const EmptyHint({super.key, required this.icon, required this.text});
final IconData icon;
final String text;
@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
return Padding(
padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
child: Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, size: 56, color: cs.outlineVariant),
const SizedBox(height: 10),
Text(
text,
textAlign: TextAlign.center,
style: TextStyle(color: cs.outline, fontWeight: FontWeight.w600),
),
],
),
),
);
}
}
/// Tombol utama bergaya modern.
class PrimaryButton extends StatelessWidget {
const PrimaryButton({super.key, required this.label, required this.onTap, this.icon});
final String label;
final VoidCallback? onTap;
final IconData? icon;
@override
Widget build(BuildContext context) {
return SizedBox(
width: double.infinity,
height: 50,
child: FilledButton(
onPressed: onTap,
style: FilledButton.styleFrom(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
],
),
),
);
}
}
InputDecoration fieldDeco(BuildContext context, String label, {String? prefix}) {
final cs = Theme.of(context).colorScheme;
return InputDecoration(
labelText: label,
prefixText: prefix,
filled: true,
fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(color: cs.primary, width: 1.5),
),
);
}
