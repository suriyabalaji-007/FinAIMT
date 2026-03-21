import 'package:flutter/material.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatelessWidget {
  final BankAccount account;
  final VoidCallback? onTap;
  
  const BalanceCard({super.key, required this.account, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(account.bankName, 
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 20),
                ),
              ],
            ),
            const Spacer(),
            Text('Balance', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(account.balance),
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              account.accountNumber, 
              style: const TextStyle(color: Colors.white38, fontSize: 14, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const QuickAction({
    super.key, 
    required this.icon, 
    required this.label, 
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label, 
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  
  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isDebit = transaction.type == TransactionType.debit;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(transaction.icon, color: Colors.white70, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(transaction.subtitle, 
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
            Text(
              '${isDebit ? '-' : '+'} ${currencyFormat.format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDebit ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
