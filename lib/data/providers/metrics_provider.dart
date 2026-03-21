import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/data/repositories/mock_repository.dart';

final metricsProvider = NotifierProvider<MetricsNotifier, FinancialSummary>(MetricsNotifier.new);

class FinancialSummary {
  final double income;
  final double expense;
  final double estimatedTax;
  final double deductions80C;
  final Map<String, double> expenseCategories;

  FinancialSummary({
    required this.income,
    required this.expense,
    required this.estimatedTax,
    required this.deductions80C,
    required this.expenseCategories,
  });

  FinancialSummary copyWith({
    double? income,
    double? expense,
    double? estimatedTax,
    double? deductions80C,
    Map<String, double>? expenseCategories,
  }) {
    return FinancialSummary(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      estimatedTax: estimatedTax ?? this.estimatedTax,
      deductions80C: deductions80C ?? this.deductions80C,
      expenseCategories: expenseCategories ?? this.expenseCategories,
    );
  }
}

class MetricsNotifier extends Notifier<FinancialSummary> {
  @override
  FinancialSummary build() {
    final tax = MockRepository.getTaxSummary();
    return FinancialSummary(
      income: tax.totalIncome,
      expense: 45500, // Mock initial
      estimatedTax: tax.estimatedTax,
      deductions80C: tax.deductions80C,
      expenseCategories: {
        'Food': 8500,
        'Bills': 12000,
        'Rent': 15000,
        'Entertainment': 10000,
      },
    );
  }

  void updateFromSocket(Map<String, dynamic> data) {
    if (data['type'] == 'EXPENSE') {
      final amount = (data['amount'] ?? 0) / 100;
      final cat = data['category'] ?? 'Misc';
      
      final newCats = Map<String, double>.from(state.expenseCategories);
      newCats[cat] = (newCats[cat] ?? 0) + amount;

      state = state.copyWith(
        expense: state.expense + amount,
        expenseCategories: newCats,
      );
      
      // Recalculate tax if needed (server also does this and sends updates)
    }
  }

  void updateFullMetrics(List<Map<String, dynamic>> metrics) {
    // Process full metrics from API if needed
  }

  void recordTransaction(Transaction txn) {
    if (txn.type == TransactionType.debit) {
      final newCats = Map<String, double>.from(state.expenseCategories);
      newCats[txn.category] = (newCats[txn.category] ?? 0) + txn.amount;

      state = state.copyWith(
        expense: state.expense + txn.amount,
        expenseCategories: newCats,
      );
    } else {
      state = state.copyWith(
        income: state.income + txn.amount,
      );
    }
  }
}
