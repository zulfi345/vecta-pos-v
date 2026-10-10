import '../../domain/entities/cash_shift_entity.dart';

class CashShiftModel extends CashShiftEntity {
  CashShiftModel({
    required super.id,
    required super.openingBalance,
    required super.totalCashSales,
    required super.totalCashOut,
    required super.expectedCash,
    required super.actualCash,
    required super.isClosed,
    required super.openedAt,
    super.closedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'openingBalance': openingBalance,
      'totalCashSales': totalCashSales,
      'totalCashOut': totalCashOut,
      'expectedCash': expectedCash,
      'actualCash': actualCash,
      'isClosed': isClosed ? 1 : 0,
      'openedAt': openedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
    };
  }

  factory CashShiftModel.fromJson(Map<String, dynamic> map) {
    return CashShiftModel(
      id: map['id'] ?? '',
      openingBalance: (map['openingBalance'] ?? 0.0).toDouble(),
      totalCashSales: (map['totalCashSales'] ?? 0.0).toDouble(),
      totalCashOut: (map['totalCashOut'] ?? 0.0).toDouble(),
      expectedCash: (map['expectedCash'] ?? 0.0).toDouble(),
      actualCash: (map['actualCash'] ?? 0.0).toDouble(),
      isClosed: map['isClosed'] == 1,
      openedAt: DateTime.parse(map['openedAt']),
      closedAt: map['closedAt'] != null ? DateTime.parse(map['closedAt']) : null,
    );
  }
}
