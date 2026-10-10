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
