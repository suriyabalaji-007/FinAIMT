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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardTheme.color : primaryColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(account.bankName, 
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9), 
                    fontSize: 14, 
                    fontWeight: FontWeight.w500
                  )
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, 
                    color: Colors.white70, 
                    size: 20
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text('Balance', 
              style: TextStyle(
                color: Colors.white.withOpacity(0.6), 
                fontSize: 12
              )
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(account.balance),
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 26, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 16),
            Text(
              account.accountNumber, 
              style: TextStyle(
                color: Colors.white.withOpacity(0.4), 
                fontSize: 14, 
                letterSpacing: 1.5
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              // In light mode, circular background with very light grey/blue like the image
              color: isDark ? Theme.of(context).cardTheme.color : const Color(0xFFF2F4F7),
              shape: BoxShape.circle,
              border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Icon(icon, color: isDark ? Colors.white : color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label, 
            style: TextStyle(
              fontSize: 12, 
              color: isDark ? AppColors.textSecondary : LightColors.textPrimary, 
              fontWeight: FontWeight.w600
            )
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
              ),
              child: Icon(transaction.icon, 
                color: isDark ? Colors.white70 : LightColors.textPrimary.withOpacity(0.7), 
                size: 24
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      color: isDark ? Colors.white : LightColors.textPrimary
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(transaction.subtitle, 
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDark ? AppColors.textHint : LightColors.textSecondary
                    )
                  ),
                ],
              ),
            ),
            Text(
              '${isDebit ? '-' : '+'} ${currencyFormat.format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDebit 
                  ? (isDark ? Colors.white : Colors.redAccent) 
                  : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
