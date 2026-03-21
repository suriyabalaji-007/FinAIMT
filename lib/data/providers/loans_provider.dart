import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/data/repositories/mock_repository.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'dart:math';

final loansProvider = NotifierProvider<LoansNotifier, List<Loan>>(LoansNotifier.new);

class LoansNotifier extends Notifier<List<Loan>> {
  @override
  List<Loan> build() {
    return MockRepository.getLoans();
  }

  void updateLoans(List<Map<String, dynamic>> data) {
    state = data.map((json) => Loan.fromJson(json)).toList();
  }

  void payEMI(String userId, String loanId) {
    final updatedLoans = state.map((loan) {
      if (loan.id == loanId) {
        final newRemaining = (loan.remainingAmount - loan.emi).clamp(0.0, double.infinity);
        return Loan(
          id: loan.id,
          title: loan.title,
          bank: loan.bank,
          totalAmount: loan.totalAmount,
          remainingAmount: newRemaining,
          emi: loan.emi,
          interestRate: loan.interestRate,
          nextDueDate: loan.nextDueDate.add(const Duration(days: 30)),
          type: loan.type,
        );
      }
      return loan;
    }).toList();
    state = updatedLoans;

    // Also deduct from bank balance
    final loanIndex = state.indexWhere((l) => l.id == loanId);
    if (loanIndex < 0) return;
    final loan = state[loanIndex];

    ref.read(financeDataProvider.notifier).addTransaction(
      Transaction(
        id: 'EMI_${DateTime.now().millisecondsSinceEpoch}',
        title: '${loan.title} EMI',
        subtitle: loan.bank,
        amount: loan.emi,
        date: DateTime.now(),
        type: TransactionType.debit,
        icon: Icons.account_balance_wallet,
        category: 'EMI',
      ),
    );
  }

  void addNewLoan({
    required String title,
    required String bank,
    required double principal,
    required double interestRate,
    required int tenureMonths,
    required String type,
  }) {
    final monthlyRate = interestRate / 12 / 100;
    final emi = monthlyRate > 0
        ? principal * monthlyRate * pow(1 + monthlyRate, tenureMonths) / (pow(1 + monthlyRate, tenureMonths) - 1)
        : principal / tenureMonths;

    final newLoan = Loan(
      id: 'L${state.length + 1}',
      title: title,
      bank: bank,
      totalAmount: principal,
      remainingAmount: principal,
      emi: emi,
      interestRate: interestRate,
      nextDueDate: DateTime.now().add(const Duration(days: 30)),
      type: type,
    );
    state = [...state, newLoan];
  }
}

// EMI Calculator — standalone utility
Map<String, double> calculateEMI({required double principal, required double rate, required int months}) {
  final monthlyRate = rate / 12 / 100;

  if (monthlyRate <= 0 || months <= 0 || principal <= 0) {
    return {'emi': 0, 'totalPayable': 0, 'totalInterest': 0};
  }

  final emi = principal * monthlyRate * pow(1 + monthlyRate, months) / (pow(1 + monthlyRate, months) - 1);
  final totalPayable = emi * months;
  final totalInterest = totalPayable - principal;

  return {
    'emi': emi,
    'totalPayable': totalPayable,
    'totalInterest': totalInterest,
  };
}

