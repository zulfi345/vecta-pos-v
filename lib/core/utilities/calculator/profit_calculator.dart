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
