import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionRecord {
  final String txnId;
  final String assetName;
  final String category; // 'Stocks', 'Post Office Schemes', 'Insurance', etc.
  final String side; // 'buy' or 'sell'
  final double quantity;
  final double pricePerUnit;
  final double totalAmount;
  final String paymentMethod; // 'UPI' or 'Card'
  final String paymentApp; // 'PhonePe', 'GPay', 'Visa ****1234', etc.
  final String fromAccount; // e.g. 'Axis Bank ****5678'
  final String toAccount; // e.g. 'India Post', 'NSE', 'LIC'
  final DateTime dateTime;
  final String status; // 'Success', 'Failed', 'Pending'

  TransactionRecord({
    required this.txnId,
    required this.assetName,
    required this.category,
    required this.side,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentApp,
    required this.fromAccount,
    required this.toAccount,
    required this.dateTime,
    this.status = 'Success',
  });

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  String get formattedAmount => NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(totalAmount);
}

class TransactionHistoryNotifier extends Notifier<List<TransactionRecord>> {
  @override
  List<TransactionRecord> build() => [];

  String addTransaction({
    required String assetName,
    required String category,
    required String side,
    required double quantity,
    required double pricePerUnit,
    required String paymentMethod,
    required String paymentApp,
    String? fromAccount,
    String? toAccount,
  }) {
    final txnId = 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
    
    String resolvedTo = toAccount ?? _resolveToAccount(category);
    String resolvedFrom = fromAccount ?? 'Your Account ****5678';

    final record = TransactionRecord(
      txnId: txnId,
      assetName: assetName,
      category: category,
      side: side,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      totalAmount: quantity * pricePerUnit,
      paymentMethod: paymentMethod,
      paymentApp: paymentApp,
      fromAccount: resolvedFrom,
      toAccount: resolvedTo,
      dateTime: DateTime.now(),
    );

    state = [record, ...state];
    return txnId;
  }

  String _resolveToAccount(String category) {
    switch (category) {
      case 'Post Office Schemes':
        return 'India Post Payments Bank';
      case 'Insurance':
        return 'LIC of India';
      case 'Mutual Funds':
        return 'AMFI Mutual Fund';
      case 'Gold':
        return 'Sovereign Gold Bond';
      default:
        return 'NSE/BSE Exchange';
    }
  }
}

final transactionHistoryProvider =
    NotifierProvider<TransactionHistoryNotifier, List<TransactionRecord>>(
        TransactionHistoryNotifier.new);
