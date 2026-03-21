import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/data/repositories/mock_repository.dart';
import 'package:fin_aimt/data/providers/metrics_provider.dart';
import 'package:fin_aimt/core/services/gemini_service.dart';

// Current Tab Provider (Riverpod v3 compatible)
final currentTabProvider =
    NotifierProvider<CurrentTabNotifier, int>(CurrentTabNotifier.new);

class CurrentTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

class FinanceState {
  final List<BankAccount> accounts;
  final List<Transaction> transactions;
  final List<CreditCard> creditCards;
  final List<Loan> loans;
  final List<AIInsight> insights;
  final UserProfile userProfile;

  FinanceState({
    required this.accounts,
    required this.transactions,
    required this.creditCards,
    required this.loans,
    required this.insights,
    required this.userProfile,
  });

  double get totalBalance => accounts.fold(0, (sum, acc) => sum + acc.balance);

  FinanceState copyWith({
    List<BankAccount>? accounts,
    List<Transaction>? transactions,
  }) {
    return FinanceState(
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      creditCards: creditCards,
      loans: loans,
      insights: insights,
      userProfile: userProfile,
    );
  }
}

final financeDataProvider = NotifierProvider<FinanceNotifier, FinanceState>(FinanceNotifier.new);

class FinanceNotifier extends Notifier<FinanceState> {
  @override
  FinanceState build() {
    return FinanceState(
      accounts: MockRepository.getAccounts(),
      transactions: MockRepository.getRecentTransactions(),
      creditCards: MockRepository.getCreditCards(),
      loans: MockRepository.getLoans(),
      insights: MockRepository.getInsights(),
      userProfile: MockRepository.getUserProfile(),
    );
  }

  void addTransaction(Transaction txn) {
    if (state.accounts.isEmpty) return;
    
    // Deduct from primary account for simplicity
    final updatedAccounts = state.accounts.map((acc) {
      if (acc == state.accounts.first) {
        return BankAccount(
          bankName: acc.bankName,
          accountNumber: acc.accountNumber,
          balance: acc.balance - (txn.type == TransactionType.debit ? txn.amount : -txn.amount),
          logoUrl: acc.logoUrl,
          isUpiEnabled: acc.isUpiEnabled,
        );
      }
      return acc;
    }).toList();

    state = state.copyWith(
      accounts: updatedAccounts,
      transactions: [txn, ...state.transactions],
    );
    ref.read(metricsProvider.notifier).recordTransaction(txn);
  }
}



