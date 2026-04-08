import 'package:flutter/material.dart';
import 'package:fin_aimt/core/theme.dart';

class UpiAppSelector extends StatelessWidget {
  final Function(String) onAppSelected;
  
  const UpiAppSelector({super.key, required this.onAppSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Text(
            'SELECT PAYMENT METHOD',
            style: TextStyle(
              color: isDark ? Colors.white30 : Colors.black45,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Wrap(
          spacing: 15,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          children: [
            _buildAppItem('Google Pay', Icons.account_balance_wallet, Colors.blue, onAppSelected, isDark),
            _buildAppItem('PhonePe', Icons.payment, Colors.purple, onAppSelected, isDark),
            _buildAppItem('Paytm', Icons.account_balance, Colors.cyan, onAppSelected, isDark),
            _buildAppItem('FinAIMT UPI', Icons.security, AppColors.primary, onAppSelected, isDark),
            _buildAppItem('Debit Card', Icons.credit_card, Colors.orange, onAppSelected, isDark),
            _buildAppItem('Credit Card', Icons.credit_score, Colors.redAccent, onAppSelected, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildAppItem(String name, IconData icon, Color color, Function(String) onTap, bool isDark) {
    return InkWell(
      onTap: () => onTap(name),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              name == 'Google Pay' ? 'GPay' : name,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
