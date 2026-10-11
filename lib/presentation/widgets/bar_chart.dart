import 'dart:math' as math;
import 'package:flutter/material.dart' hide Text;
class BarChart extends StatelessWidget {
const BarChart({
super.key,
required this.values,
required this.labels,
this.labelEvery = 1,
this.height = 190,
});
final List<double> values;
final List<String> labels;
final int labelEvery;
final double height;
@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
return SizedBox(
height: height,
width: double.infinity,
child: CustomPaint(
painter: _BarPainter(
values: values,
labels: labels,
labelEvery: labelEvery,
c1: cs.primary,
c2: cs.tertiary,
grid: cs.outlineVariant,
textColor: cs.onSurfaceVariant,
),
),
);
}
}
class _BarPainter extends CustomPainter {
_BarPainter({
required this.values,
required this.labels,
required this.labelEvery,
required this.c1,
required this.c2,
required this.grid,
required this.textColor,
});
final List<double> values;
final List<String> labels;
final int labelEvery;
final Color c1;
final Color c2;
final Color grid;
final Color textColor;
@override
void paint(Canvas canvas, Size size) {
const bottom = 24.0;
const top = 8.0;
final chartH = size.height - bottom - top;
final gridPaint = Paint()
..color = grid.withValues(alpha: 0.6)
..strokeWidth = 1;
for (var i = 0; i <= 3; i++) {
final y = top + chartH * i / 3;
canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
}
if (values.isEmpty) return;
var maxV = 1.0;
for (final v in values) {
maxV = math.max(maxV, v);
}
final slot = size.width / values.length;
final barW = math.min(slot * 0.62, 28.0);
for (var i = 0; i < values.length; i++) {
final v = values[i];
final h = v <= 0 ? 0.0 : math.max(chartH * v / maxV, 3.0);
final x = slot * i + (slot - barW) / 2;
if (h > 0) {
final rect = RRect.fromRectAndCorners(
Rect.fromLTWH(x, top + chartH - h, barW, h),
topLeft: const Radius.circular(7),
topRight: const Radius.circular(7),
);
final paint = Paint()
..shader = LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [c1, c2.withValues(alpha: 0.75)],
).createShader(Rect.fromLTWH(x, top, barW, chartH));
canvas.drawRRect(rect, paint);
}
if (i % labelEvery == 0 && i < labels.length) {
final tp = TextPainter(
text: TextSpan(text: labels[i], style: TextStyle(fontSize: 10, color: textColor)),
textDirection: TextDirection.ltr,
)..layout();
tp.paint(canvas, Offset(slot * i + slot / 2 - tp.width / 2, size.height - bottom + 7));
}
}
}
@override
bool shouldRepaint(covariant _BarPainter old) => true;
}
