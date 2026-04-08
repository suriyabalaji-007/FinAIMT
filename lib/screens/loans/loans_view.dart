import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/widgets/global_header.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fin_aimt/data/providers/loans_provider.dart';
import 'package:fin_aimt/widgets/unified_payment_flow.dart';

class LoansView extends ConsumerWidget {
  const LoansView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(loansProvider);
    final financeData = ref.watch(financeDataProvider);
    final cards = financeData.creditCards;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? Colors.white : LightColors.textPrimary;
    final textSecondary = isDark ? Colors.white54 : LightColors.textSecondary;

    double totalEmi = loans.fold(0, (sum, loan) => sum + loan.emi);
    double totalRemaining = loans.fold(0, (sum, loan) => sum + loan.remainingAmount);
    int daysToNextDue = loans.isNotEmpty 
      ? loans.map((l) => l.nextDueDate.difference(DateTime.now()).inDays).reduce((a, b) => a < b ? a : b)
      : 0;

    void showPayEmiDialog(Loan loan) {
      UnifiedPaymentFlow.show(
        context: context,
        ref: ref,
        assetName: 'EMI Repayment: ${loan.title}',
        category: 'Loans',
        quantity: 1,
        pricePerUnit: loan.emi,
        side: 'buy', // Using 'buy' as the positive transaction side for repayment
        itemId: loan.id,
      ).then((success) {
        if (success) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${currencyFormat.format(loan.emi)} EMI paid for ${loan.title}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: primaryColor,
            ),
          );
        }
      });
    }

    void showEmiCalculator() {
      final principalCtrl = TextEditingController();
      final rateCtrl = TextEditingController(text: '8.5');
      final tenureCtrl = TextEditingController(text: '120');
      double emi = 0, totalPayable = 0, totalInterest = 0;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setSheetState) {
            void calculate() {
              final p = double.tryParse(principalCtrl.text) ?? 0;
              final r = double.tryParse(rateCtrl.text) ?? 0;
              final n = int.tryParse(tenureCtrl.text) ?? 0;
              if (p > 0 && r > 0 && n > 0) {
                final result = calculateEMI(principal: p, rate: r, months: n);
                setSheetState(() {
                  emi = result['emi'] ?? 0;
                  totalPayable = result['totalPayable'] ?? 0;
                  totalInterest = result['totalInterest'] ?? 0;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text('EMI Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary))),
                  const SizedBox(height: 24),
                  _buildCalcField(context, principalCtrl, 'Loan Amount (₹)', Icons.currency_rupee),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildCalcField(context, rateCtrl, 'Rate %', Icons.percent)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCalcField(context, tenureCtrl, 'Months', Icons.calendar_month)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Calculate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  if (emi > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          _resultRow(context, 'Monthly EMI', currencyFormat.format(emi), primaryColor),
                          const SizedBox(height: 10),
                          _resultRow(context, 'Total Payable', currencyFormat.format(totalPayable), textPrimary.withOpacity(0.7)),
                          const SizedBox(height: 10),
                          _resultRow(context, 'Total Interest', currencyFormat.format(totalInterest), Colors.orangeAccent),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          });
        },
      );
    }

    void showApplyLoanDialog() {
      final titleCtrl = TextEditingController();
      final bankCtrl = TextEditingController(text: 'HDFC Bank');
      final amountCtrl = TextEditingController();
      final rateCtrl = TextEditingController(text: '9.0');
      final tenureCtrl = TextEditingController(text: '60');
      String selectedType = 'Personal';

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Apply for Loan', style: TextStyle(color: textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField(context, titleCtrl, 'Loan Title'),
                  const SizedBox(height: 10),
                  _buildDialogField(context, bankCtrl, 'Bank Name'),
                  const SizedBox(height: 10),
                  _buildDialogField(context, amountCtrl, 'Principal Amount (₹)', isNumber: true),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildDialogField(context, rateCtrl, 'Rate %', isNumber: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildDialogField(context, tenureCtrl, 'Months', isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: Theme.of(context).cardTheme.color,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Loan Type',
                      labelStyle: TextStyle(color: textSecondary),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor), borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Personal', 'Home', 'Education', 'Vehicle', 'Business'].map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setDialogState(() => selectedType = val ?? 'Personal'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () {
                  final principal = double.tryParse(amountCtrl.text) ?? 0;
                  final rate = double.tryParse(rateCtrl.text) ?? 0;
                  final months = int.tryParse(tenureCtrl.text) ?? 0;
                  if (principal > 0 && rate > 0 && months > 0 && titleCtrl.text.isNotEmpty) {
                    ref.read(loansProvider.notifier).addNewLoan(
                      title: titleCtrl.text,
                      bank: bankCtrl.text,
                      principal: principal,
                      interestRate: rate,
                      tenureMonths: months,
                      type: selectedType,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🎉 ${titleCtrl.text} approved!'), behavior: SnackBarBehavior.floating, backgroundColor: primaryColor),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalHeader(
            title: 'EMI & Loans',
            subtitle: 'Active Loans & Credit',
            showLogo: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Row(
              children: [
                _headerAction(context, Icons.calculate_outlined, 'Calculator', () => showEmiCalculator()),
                const SizedBox(width: 10),
                _headerAction(context, Icons.add_circle_outline, 'New Loan', () => showApplyLoanDialog()),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Expanded(child: _summaryCard(context, 'Total EMI/mo', currencyFormat.format(totalEmi), Icons.payments_outlined, primaryColor)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard(context, 'Outstanding', currencyFormat.format(totalRemaining), Icons.account_balance_wallet, Colors.orangeAccent)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Expanded(child: _summaryCard(context, 'Active Loans', '${loans.length}', Icons.receipt_long, Colors.blueAccent)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard(context, 'Next Due', '$daysToNextDue days', Icons.event, Colors.redAccent)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
            child: Text('EMI Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          ),
          if (loans.isNotEmpty)
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 25),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color, 
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 35,
                        sections: loans.asMap().entries.map((e) {
                          final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink];
                          return PieChartSectionData(
                            color: colors[e.key % colors.length],
                            value: e.value.emi,
                            title: '${(e.value.emi / totalEmi * 100).toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: loans.asMap().entries.map((e) {
                      final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 8),
                            Text(e.value.type, style: TextStyle(color: textSecondary, fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
            child: Text('Active Loans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          ),
          ...loans.map((loan) => _buildLoanItem(context, loan, currencyFormat, () => showPayEmiDialog(loan))),

          if (cards.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
              child: Text('Credit Card Utilization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            ),
            ...cards.map((card) => _buildCardUtilizationItem(context, card, currencyFormat)),
          ],

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _headerAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryColor, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (isDark ? color.withOpacity(0.15) : Colors.black.withOpacity(0.05))),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: isDark ? Colors.white30 : LightColors.textHint, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : LightColors.textPrimary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : LightColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: isDark ? Colors.white : LightColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _resultRow(BuildContext context, String label, String value, Color valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : LightColors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildCalcField(BuildContext context, TextEditingController ctrl, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: ctrl,
      style: TextStyle(color: isDark ? Colors.white : LightColors.textPrimary),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? AppColors.textHint : LightColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: primaryColor, size: 18),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: (isDark ? Colors.white10 : Colors.black12)), borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor), borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDialogField(BuildContext context, TextEditingController ctrl, String label, {bool isNumber = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: ctrl,
      style: TextStyle(color: isDark ? Colors.white : LightColors.textPrimary, fontSize: 14),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? AppColors.textHint : LightColors.textHint, fontSize: 12),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: (isDark ? Colors.white10 : Colors.black12)), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor), borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildLoanItem(BuildContext context, Loan loan, NumberFormat format, VoidCallback onPayEmi) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? Colors.white : LightColors.textPrimary;
    final textSecondary = isDark ? Colors.white30 : LightColors.textSecondary;
    final daysUntilDue = loan.nextDueDate.difference(DateTime.now()).inDays;
    final isUrgent = daysUntilDue <= 7;
    final isPaid = loan.remainingAmount <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUrgent ? Colors.redAccent.withOpacity(0.3) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(loan.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
                        if (isPaid) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text('PAID', style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Text('${loan.bank} • ${loan.interestRate}% p.a.', style: TextStyle(color: textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${format.format(loan.emi)}/mo', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14)),
                  if (!isPaid)
                    Text('Due in $daysUntilDue days', style: TextStyle(color: isUrgent ? Colors.redAccent : textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: loan.progress.clamp(0.0, 1.0),
              backgroundColor: (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              valueColor: AlwaysStoppedAnimation<Color>(isPaid ? primaryColor : (isUrgent ? Colors.redAccent : primaryColor)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paid: ${format.format(loan.totalAmount - loan.remainingAmount)}', style: TextStyle(fontSize: 11, color: textSecondary)),
              Text('Remaining: ${format.format(loan.remainingAmount)}', style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
          if (!isPaid) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPayEmi,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Pay EMI', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardUtilizationItem(BuildContext context, CreditCard card, NumberFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? Colors.white : LightColors.textPrimary;
    final textSecondary = isDark ? Colors.white30 : LightColors.textSecondary;
    final utilization = card.utilization;
    final isHigh = utilization > 50;
    final color = isHigh ? Colors.orange : primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(card.cardName, style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${utilization.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (utilization / 100).clamp(0.0, 1.0),
              backgroundColor: (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Limit: ${format.format(card.limit)}', style: TextStyle(fontSize: 11, color: textSecondary)),
              Text('Due: ${format.format(card.balance)}', style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// Logic for EMI calculation helper
Map<String, double> calculateEMI({required double principal, required double rate, required int months}) {
  final double monthlyRate = rate / (12 * 100);
  final double emi = principal * monthlyRate * (pow(1 + monthlyRate, months)) / (pow(1 + monthlyRate, months) - 1);
  final double totalPayable = emi * months;
  final double totalInterest = totalPayable - principal;
  
  return {
    'emi': emi,
    'totalPayable': totalPayable,
    'totalInterest': totalInterest,
  };
}

num pow(num x, num y) {
  num result = 1;
  for (int i = 0; i < y; i++) {
    result *= x;
  }
  return result;
}
