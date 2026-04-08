import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/data/services/investment_service.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'dart:async';

// User's current portfolio
final userPortfolioProvider = NotifierProvider<UserPortfolioNotifier, List<Investment>>(UserPortfolioNotifier.new);

class UserPortfolioNotifier extends Notifier<List<Investment>> {
  final InvestmentService _investmentService = InvestmentService();

  @override
  List<Investment> build() {
    _fetchInitialPortfolio();
    return [];
  }

  Future<void> _fetchInitialPortfolio() async {
    try {
      final portfolio = await _investmentService.getPortfolio();
      state = portfolio;
    } catch (e) {
      // Handle error or keep empty
    }
  }

  Future<void> fetchPortfolio() async {
    try {
      final portfolio = await _investmentService.getPortfolio();
      state = portfolio;
    } catch (e) {
       // Log or show error
    }
  }

  Future<void> tradeInvestment({
    required String assetId,
    required String assetName,
    required String category,
    required double quantity,
    required double price,
    required String side,
  }) async {
    try {
      await _investmentService.trade(
        assetId: assetId,
        assetName: assetName,
        category: category,
        quantity: quantity,
        price: price,
        side: side,
      );
      // Refresh portfolio from server after trade
      await fetchPortfolio();
    } catch (e) {
      // Handle error
    }
  }
}

// Combined dynamic investment data
final dynamicInvestmentsProvider = Provider<List<Investment>>((ref) {
  final portfolio = ref.watch(userPortfolioProvider);
  final marketData = ref.watch(marketDataProvider);

  return portfolio.map((inv) {
    // Normalize category names for rebranding
    String category = inv.category;
    if (category == 'Govt Schemes') {
      category = 'Post Office Schemes';
    }

    if (marketData.containsKey(inv.assetId)) {
      final data = marketData[inv.assetId]!;
      final currentPrice = data.currentPrice;
      final currentVal = inv.quantity * currentPrice;
      final diff = currentVal - inv.investedAmount;
      final changePerc = inv.investedAmount > 0 ? (diff / inv.investedAmount) * 100 : 0.0;

      return inv.copyWith(
        category: category,
        currentAmount: currentVal,
        changePercentage: double.parse(changePerc.toStringAsFixed(2)),
        history: data.history,
      );
    }
    return inv.copyWith(category: category);
  }).toList();
});
