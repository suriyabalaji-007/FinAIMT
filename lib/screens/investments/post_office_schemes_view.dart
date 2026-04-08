import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/data/repositories/mock_repository.dart';
import 'package:fin_aimt/widgets/upi_pin_dialog.dart';
import 'package:fin_aimt/screens/upi/payment_success_view.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fin_aimt/widgets/unified_payment_flow.dart';

class PostOfficeSchemesView extends ConsumerStatefulWidget {
  const PostOfficeSchemesView({super.key});

  @override
  ConsumerState<PostOfficeSchemesView> createState() => _PostOfficeSchemesViewState();
}

class _PostOfficeSchemesViewState extends ConsumerState<PostOfficeSchemesView> {
  final List<PostOfficeScheme> schemes = MockRepository.getPostOfficeSchemes();
  late PostOfficeScheme selectedScheme;
  final TextEditingController amountCtrl = TextEditingController(text: '100000');
  double amount = 100000;

  @override
  void initState() {
    super.initState();
    selectedScheme = schemes.first;
    amountCtrl.addListener(() {
      final val = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
      if (val != amount) {
        setState(() {
          amount = val;
        });
      }
    });
  }

  double get totalPrincipal => amount * (selectedScheme.type == 'RD' ? (selectedScheme.tenureYears * 12) : 1);
  double get annualInterest => (totalPrincipal * selectedScheme.interestRate) / 100;
  double get monthlyInterest => annualInterest / 12;
  
  double get maturityValue {
    if (selectedScheme.type == 'MIS' || selectedScheme.type == 'SCSS') {
      return totalPrincipal; 
    } else if (selectedScheme.type == 'KVP') {
      return totalPrincipal * 2; 
    } else if (selectedScheme.type == 'RD') {
      double r = selectedScheme.interestRate / 100;
      double t = selectedScheme.tenureYears.toDouble();
      return amount * (((pow(1 + r/4, 4*t) - 1)) / (1 - pow(1 + r/4, -1/3)));
    } else {
      return totalPrincipal * pow((1 + (selectedScheme.interestRate / 100)), selectedScheme.tenureYears);
    }
  }

  void _showPaymentSelection() {
    if (amount < selectedScheme.minInvestment) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum investment for ${selectedScheme.name} is ₹${selectedScheme.minInvestment}')),
      );
      return;
    }

    UnifiedPaymentFlow.show(
      context: context,
      ref: ref,
      assetName: selectedScheme.name,
      category: 'Post Office Schemes',
      quantity: 1,
      pricePerUnit: amount,
      side: 'buy',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isMonthlyScheme = selectedScheme.type == 'RD' || selectedScheme.type == 'MIS';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Post Office India', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade700, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.white, size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('100% Tax Efficient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${selectedScheme.interestRate}% Guaranteed Yearly Returns', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Select Post Office Scheme', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PostOfficeScheme>(
                  value: selectedScheme,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardTheme.color,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: schemes.map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.interestRate}%)', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() {
                      selectedScheme = val;
                      if (val.type == 'RD' && amount > 50000) amount = 5000;
                      amountCtrl.text = amount.toStringAsFixed(0);
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Text(isMonthlyScheme ? 'Monthly Deposit Amount' : 'Lump Sum Investment Amount', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2)),
              child: Column(
                children: [
                   TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(prefixText: '₹ ', prefixStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold), border: InputBorder.none),
                  ),
                  Slider(
                    value: amount < 500 ? 500 : (amount > 1500000 ? 1500000 : amount),
                    min: 500, max: 1500000, divisions: 100,
                    onChanged: (val) { setState(() { amount = val; amountCtrl.text = val.toStringAsFixed(0); }); },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text('Projected Returns Report', style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
              child: Column(
                children: [
                  if (selectedScheme.type == 'MIS' || selectedScheme.type == 'SCSS') _buildStatRow('Monthly Income', fmt.format(monthlyInterest), Icons.payments, Colors.blue, isLarge: true),
                  if (selectedScheme.type != 'MIS' && selectedScheme.type != 'SCSS') _buildStatRow('Total Interest Earned', fmt.format(maturityValue - totalPrincipal), Icons.trending_up, Colors.orange),
                  const Divider(height: 24),
                  _buildStatRow('Total Principal', fmt.format(totalPrincipal), Icons.history, Colors.grey),
                  const Divider(height: 24),
                  _buildStatRow('Maturity Value (${selectedScheme.tenureYears} Yrs)', fmt.format(maturityValue), Icons.account_balance_wallet, Colors.green, isLarge: true),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Container(
              width: double.infinity, height: 60,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]),
              child: ElevatedButton(
                onPressed: _showPaymentSelection,
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('Invest ${fmt.format(amount)} Securely', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.security, size: 14, color: Colors.grey), const SizedBox(width: 6), Text('Secured by BHIM UPI & PCI-DSS Encryption', style: TextStyle(color: Colors.grey, fontSize: 11))])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color, {bool isLarge = false}) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Text(value, style: TextStyle(color: isLarge ? color : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87), fontWeight: FontWeight.bold, fontSize: isLarge ? 20 : 16)),
      ],
    );
  }
}
