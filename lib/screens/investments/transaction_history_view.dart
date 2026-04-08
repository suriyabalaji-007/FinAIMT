import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/transaction_provider.dart';

class TransactionHistoryView extends ConsumerWidget {
  const TransactionHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            Text('${transactions.length} records', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
      ),
      body: transactions.isEmpty
          ? _buildEmptyState(isDark, primaryColor)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                return _TransactionCard(txn: txn, isDark: isDark, primaryColor: primaryColor);
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 48, color: primaryColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text('No Transactions Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Your investment payments will appear here', style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13)),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionRecord txn;
  final bool isDark;
  final Color primaryColor;

  const _TransactionCard({required this.txn, required this.isDark, required this.primaryColor});

  Color get _categoryColor {
    switch (txn.category) {
      case 'Post Office Schemes': return Colors.orange;
      case 'Insurance': return Colors.blue;
      case 'Mutual Funds': return Colors.purple;
      case 'Gold': return Colors.amber;
      case 'ETFs': return Colors.teal;
      default: return primaryColor;
    }
  }

  IconData get _categoryIcon {
    switch (txn.category) {
      case 'Post Office Schemes': return Icons.markunread_mailbox;
      case 'Insurance': return Icons.health_and_safety;
      case 'Mutual Funds': return Icons.pie_chart;
      case 'Gold': return Icons.monetization_on;
      case 'ETFs': return Icons.candlestick_chart;
      default: return Icons.show_chart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = txn.side == 'buy';

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _categoryColor.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(_categoryIcon, color: _categoryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(txn.assetName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                      Text(txn.category, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black38)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isBuy ? '-' : '+'}${txn.formattedAmount}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isBuy ? Colors.redAccent : Colors.green),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isBuy ? primaryColor : Colors.green).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isBuy ? 'BUY' : 'SELL',
                        style: TextStyle(color: isBuy ? primaryColor : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniInfo(Icons.receipt_outlined, txn.txnId.length > 12 ? txn.txnId.substring(0, 12) + '...' : txn.txnId, isDark),
                const Spacer(),
                _buildMiniInfo(
                  txn.paymentMethod == 'UPI' ? Icons.account_balance : Icons.credit_card,
                  txn.paymentApp,
                  isDark,
                ),
                const Spacer(),
                _buildMiniInfo(Icons.access_time, txn.formattedDate.split(',')[0], isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: isDark ? Colors.white24 : Colors.black26),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TransactionDetailSheet(txn: txn, isDark: isDark, primaryColor: primaryColor),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final TransactionRecord txn;
  final bool isDark;
  final Color primaryColor;

  const _TransactionDetailSheet({required this.txn, required this.isDark, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final isBuy = txn.side == 'buy';

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 25),

          // Status icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Transaction ${txn.status}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 6),
          Text(
            '${isBuy ? 'Bought' : 'Sold'} ${txn.quantity.toStringAsFixed(2)} units of ${txn.assetName}',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${isBuy ? '-' : '+'}${txn.formattedAmount}',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isBuy ? Colors.redAccent : Colors.green),
          ),
          const SizedBox(height: 25),

          // Full receipt
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              children: [
                _row('Transaction ID', txn.txnId),
                _div(),
                _row('Date & Time', txn.formattedDate),
                _div(),
                _row('From', txn.fromAccount),
                _div(),
                _row('To', txn.toAccount),
                _div(),
                _row('Payment Method', txn.paymentMethod),
                _div(),
                _row('Payment App / Card', txn.paymentApp),
                _div(),
                _row('Asset', txn.assetName),
                _div(),
                _row('Category', txn.category),
                _div(),
                _row('Quantity', txn.quantity.toStringAsFixed(4)),
                _div(),
                _row('Price/Unit', txn.formattedAmount.replaceAll(RegExp(r'[\d,]+'), (txn.pricePerUnit.toStringAsFixed(2)))),
                _div(),
                _row('Total Amount', txn.formattedAmount, isBold: true, valueColor: isBuy ? Colors.redAccent : Colors.green),
                _div(),
                _row('Status', txn.status, valueColor: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? (isDark ? Colors.white : Colors.black87), fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _div() => Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), height: 1);
}
