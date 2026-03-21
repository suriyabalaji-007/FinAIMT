import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/data/repositories/mock_repository.dart';
import 'dart:async';
import 'dart:math';

// State of real-time market prices (AssetID -> Price in Paise)
final priceUpdatesProvider = NotifierProvider<PriceUpdatesNotifier, Map<String, int>>(PriceUpdatesNotifier.new);

class PriceUpdatesNotifier extends Notifier<Map<String, int>> {
  Timer? _timer;
  final Random _random = Random();

  @override
  Map<String, int> build() {
    ref.onDispose(() => _timer?.cancel());
    _startPriceSimulation();
    return {
      'RELIANCE': 285000,
      'HDFC_FUND': 542000,
      'GOLD': 115000,
      'PPF': 1620000,
      'LIC': 150000,
    };
  }

  void _startPriceSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final updated = Map<String, int>.from(state);
      updated.forEach((key, price) {
        // Simulate ±0.3% fluctuation
        final movement = (price * (_random.nextDouble() * 0.006 - 0.003)).round();
        updated[key] = price + movement;
      });
      state = updated;
    });
  }

  void updatePrices(Map<String, int> newPrices) {
    state = {...state, ...newPrices};
  }
}

// User's current portfolio
final userPortfolioProvider = NotifierProvider<UserPortfolioNotifier, List<Investment>>(UserPortfolioNotifier.new);

class UserPortfolioNotifier extends Notifier<List<Investment>> {
  @override
  List<Investment> build() {
    return MockRepository.getInvestments();
  }

  void updatePortfolio(List<Map<String, dynamic>> data) {
    state = data.map((json) => Investment.fromJson(json)).toList();
  }

  void tradeInvestment({
    required String userId,
    required String assetId,
    required String assetName,
    required String category,
    required double quantity,
    required double price,
    required String side,
  }) {
    final existing = state.indexWhere((inv) => inv.assetId == assetId);

    if (side == 'buy') {
      if (existing >= 0) {
        final inv = state[existing];
        final newQty = inv.quantity + quantity;
        final newInvested = inv.investedAmount + (quantity * price);
        final newAvg = newInvested / newQty;
        final updatedList = [...state];
        updatedList[existing] = Investment(
          id: inv.id,
          assetId: inv.assetId,
          name: inv.name,
          investedAmount: newInvested,
          currentAmount: newQty * price,
          changePercentage: inv.changePercentage,
          category: inv.category,
          history: [...inv.history, price],
          quantity: newQty,
          averagePrice: newAvg,
        );
        state = updatedList;
      } else {
        state = [
          ...state,
          Investment(
            assetId: assetId,
            name: assetName,
            investedAmount: quantity * price,
            currentAmount: quantity * price,
            changePercentage: 0,
            category: category,
            history: [price],
            quantity: quantity,
            averagePrice: price,
          ),
        ];
      }
    } else if (side == 'sell' && existing >= 0) {
      final inv = state[existing];
      final newQty = (inv.quantity - quantity).clamp(0.0, double.infinity);
      if (newQty <= 0) {
        state = state.where((i) => i.assetId != assetId).toList();
      } else {
        final newInvested = newQty * inv.averagePrice;
        final updatedList = [...state];
        updatedList[existing] = Investment(
          id: inv.id,
          assetId: inv.assetId,
          name: inv.name,
          investedAmount: newInvested,
          currentAmount: newQty * price,
          changePercentage: inv.changePercentage,
          category: inv.category,
          history: [...inv.history, price],
          quantity: newQty,
          averagePrice: inv.averagePrice,
        );
        state = updatedList;
      }
    }
  }
}

// Combined dynamic investment data
final dynamicInvestmentsProvider = Provider<List<Investment>>((ref) {
  final portfolio = ref.watch(userPortfolioProvider);
  final prices = ref.watch(priceUpdatesProvider);

  return portfolio.map((inv) {
    if (prices.containsKey(inv.assetId)) {
      final currentPrice = prices[inv.assetId]! / 100;
      final currentVal = inv.quantity * currentPrice;
      final diff = currentVal - inv.investedAmount;
      final changePerc = inv.investedAmount > 0 ? (diff / inv.investedAmount) * 100 : 0.0;

      // Maintain a rolling history of the last 60 points (1 minute of 1s ticks)
      final newHistory = [...inv.history, currentPrice];
      if (newHistory.length > 60) {
        newHistory.removeAt(0);
      }

      return inv.copyWith(
        currentAmount: currentVal,
        changePercentage: double.parse(changePerc.toStringAsFixed(2)),
        history: newHistory,
      );
    }
    return inv;
  }).toList();
});
