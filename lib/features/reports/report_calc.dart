import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/di/app_providers.dart';
import '../../core/i18n/app_lang.dart';
import '../../domain/entities/ordered_product_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../presentation/providers/auth/auth_notifier.dart';
/// Semua transaksi milik user (dari database lokal HP).
final reportDataProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
final userId = ref.read(authNotifierProvider).user?.id;
if (userId == null) return <TransactionEntity>[];
final res = await ref.read(transactionLocalDatasourceProvider).getAllUserTransactions(userId);
final list = res.data ?? [];
return list.map((e) => e.toEntity()).toList();
});
/// Semua produk milik user (dari database lokal HP).
final allProductsProvider = FutureProvider.autoDispose<List<ProductEntity>>((ref) async {
final userId = ref.read(authNotifierProvider).user?.id;
if (userId == null) return <ProductEntity>[];
final res = await ref.read(productLocalDatasourceProvider).getAllUserProducts(userId);
final list = res.data ?? [];
return list.map((e) => e.toEntity()).toList();
});
enum ReportPeriod { day, week, month }
class ProductStat {
ProductStat(this.name);
final String name;
int qty = 0;
int revenue = 0;
}
class ReportData {
ReportData(this.start, this.end);
final DateTime start;
final DateTime end;
int revenue = 0;
int count = 0;
int items = 0;
int cash = 0;
int bank = 0;
int prevRevenue = 0;
List<double> bars = [];
List<String> labels = [];
int labelEvery = 1;
List<ProductStat> top = [];
int get avg => count == 0 ? 0 : (revenue / count).round();
}
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
(DateTime, DateTime) rangeFor(ReportPeriod p, DateTime anchor) {
final a = _dateOnly(anchor);
switch (p) {
case ReportPeriod.day:
return (a, DateTime(a.year, a.month, a.day + 1));
case ReportPeriod.week:
final s = DateTime(a.year, a.month, a.day - (a.weekday - 1));
return (s, DateTime(s.year, s.month, s.day + 7));
case ReportPeriod.month:
return (DateTime(a.year, a.month, 1), DateTime(a.year, a.month + 1, 1));
}
}
DateTime? parseLocal(String? s) {
if (s == null || s.isEmpty) return null;
return DateTime.tryParse(s)?.toLocal();
}
List<ProductStat> topProducts(List<TransactionEntity> txs, DateTime? from, {int limit = 5}) {
final stats = <int, ProductStat>{};
for (final t in txs) {
final at = parseLocal(t.createdAt);
if (at == null) continue;
if (from != null && at.isBefore(from)) continue;
for (final OrderedProductEntity o in t.orderedProducts ?? const <OrderedProductEntity>[]) {
final s = stats.putIfAbsent(o.productId, () => ProductStat(o.name));
s.qty += o.quantity;
s.revenue += o.price * o.quantity;
}
}
final list = stats.values.toList()..sort((a, b) => b.qty.compareTo(a.qty));
return list.length > limit ? list.sublist(0, limit) : list;
}
ReportData buildReport(List<TransactionEntity> all, ReportPeriod p, DateTime anchor) {
final (start, end) = rangeFor(p, anchor);
final d = ReportData(start, end);
late final int n;
switch (p) {
case ReportPeriod.day:
n = 24;
d.labelEvery = 3;
d.labels = List<String>.generate(24, (i) => '$i');
break;
case ReportPeriod.week:
n = 7;
d.labelEvery = 1;
d.labels = List<String>.generate(7, (i) => dayName(i + 1, short: true));
break;
case ReportPeriod.month:
n = DateTime(start.year, start.month + 1, 0).day;
d.labelEvery = 5;
d.labels = List<String>.generate(n, (i) => '${i + 1}');
break;
}
d.bars = List<double>.filled(n, 0);
DateTime prevAnchor;
switch (p) {
case ReportPeriod.day:
prevAnchor = DateTime(start.year, start.month, start.day - 1);
break;
case ReportPeriod.week:
prevAnchor = DateTime(start.year, start.month, start.day - 7);
break;
case ReportPeriod.month:
prevAnchor = DateTime(start.year, start.month - 1, 1);
break;
}
final (ps, pe) = rangeFor(p, prevAnchor);
final inRange = <TransactionEntity>[];
for (final t in all) {
final at = parseLocal(t.createdAt);
if (at == null) continue;
if (!at.isBefore(ps) && at.isBefore(pe)) d.prevRevenue += t.totalAmount;
if (at.isBefore(start) || !at.isBefore(end)) continue;
inRange.add(t);
d.revenue += t.totalAmount;
d.count += 1;
final lines = t.orderedProducts;
d.items += (lines == null || lines.isEmpty)
? t.totalOrderedProduct
: lines.fold<int>(0, (sum, e) => sum + e.quantity);
if (t.paymentMethod == 'cash') {
d.cash += t.totalAmount;
} else {
d.bank += t.totalAmount;
}
int idx;
switch (p) {
case ReportPeriod.day:
idx = at.hour;
break;
case ReportPeriod.week:
idx = at.weekday - 1;
break;
case ReportPeriod.month:
idx = at.day - 1;
break;
}
if (idx >= 0 && idx < n) d.bars[idx] += t.totalAmount.toDouble();
}
d.top = topProducts(inRange, null);
return d;
}
