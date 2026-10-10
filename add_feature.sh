#!/bin/bash

# 1. Validasi direktori proyek (memastikan berada di root flutter_pos)
if [ ! -f "pubspec.yaml" ] || [ ! -d "lib" ]; then
    echo "❌ Error: Direktori ini bukan root proyek Flutter POS yang valid!"
    exit 1
fi

echo "🚀 Menambahkan modul fitur manajemen (Shift Kasir & Kalkulator Laba Rugi)..."

# 2. Membuat folder struktur baru
mkdir -p lib/data/models
mkdir -p lib/domain/entities
mkdir -p lib/core/utilities/calculator

# 3. Membuat file Entitas Shift Kasir (Domain Layer)
cat << 'EOF' > lib/domain/entities/cash_shift_entity.dart
class CashShiftEntity {
  final String id;
  final double openingBalance;
  final double totalCashSales;
  final double totalCashOut;
  final double expectedCash;
  final double actualCash;
  final bool isClosed;
  final DateTime openedAt;
  final DateTime? closedAt;

  CashShiftEntity({
    required this.id,
    required this.openingBalance,
    required this.totalCashSales,
    required this.totalCashOut,
    required this.expectedCash,
    required this.actualCash,
    required this.isClosed,
    required this.openedAt,
    this.closedAt,
  });

  double get discrepancy => actualCash - expectedCash;
}
EOF

# 4. Membuat file Model Shift Kasir (Data Layer)
cat << 'EOF' > lib/data/models/cash_shift_model.dart
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
EOF

# 5. Membuat Kalkulator Laba Rugi / HPP Sederhana (Core Utility)
cat << 'EOF' > lib/core/utilities/calculator/profit_calculator.dart
class ProfitCalculator {
  static double calculateItemProfit({
    required double sellingPrice,
    required double purchaseCost,
    required int quantity,
  }) {
    return (sellingPrice - purchaseCost) * quantity;
  }

  static Map<String, double> summarizeFinancials({
    required List<Map<String, dynamic>> soldItems,
  }) {
    double totalRevenue = 0;
    double totalCost = 0;

    for (var item in soldItems) {
      double price = (item['price'] ?? 0.0).toDouble();
      double cost = (item['purchaseCost'] ?? 0.0).toDouble();
      int qty = (item['quantity'] ?? 0).toInt();

      totalRevenue += price * qty;
      totalCost += cost * qty;
    }

    return {
      'revenue': totalRevenue,
      'cost': totalCost,
      'netProfit': totalRevenue - totalCost,
    };
  }
}
EOF

echo "✅ Selesai! File modul baru berhasil ditambahkan tanpa merusak struktur file Anda."

