import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/widgets/global_header.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fin_aimt/data/providers/loans_provider.dart';

class LoansView extends ConsumerWidget {
  const LoansView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(loansProvider);
    final financeData = ref.watch(financeDataProvider);
    final cards = financeData.creditCards;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    double totalEmi = loans.fold(0, (sum, loan) => sum + loan.emi);
    double totalRemaining = loans.fold(0, (sum, loan) => sum + loan.remainingAmount);
    int daysToNextDue = loans.isNotEmpty 
      ? loans.map((l) => l.nextDueDate.difference(DateTime.now()).inDays).reduce((a, b) => a < b ? a : b)
      : 0;

    void showPayEmiDialog(Loan loan) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Pay EMI — ${loan.title}', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('EMI Amount', currencyFormat.format(loan.emi)),
              _infoRow('Bank', loan.bank),
              _infoRow('Interest', '${loan.interestRate}% p.a.'),
              _infoRow('Remaining', currencyFormat.format(loan.remainingAmount)),
              _infoRow('Next Due', DateFormat('dd MMM yyyy').format(loan.nextDueDate)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textHint))),
            ElevatedButton(
              onPressed: loan.remainingAmount > 0 ? () {
                ref.read(loansProvider.notifier).payEMI('USER_ID', loan.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${currencyFormat.format(loan.emi)} EMI paid for ${loan.title}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Pay Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    void showEmiCalculator() {
      final principalCtrl = TextEditingController();
      final rateCtrl = TextEditingController(text: '8.5');
      final tenureCtrl = TextEditingController(text: '120');
      double emi = 0, totalPayable = 0, totalInterest = 0;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
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
                  const Center(child: Text('EMI Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                  const SizedBox(height: 24),
                  _buildCalcField(principalCtrl, 'Loan Amount (₹)', Icons.currency_rupee),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildCalcField(rateCtrl, 'Rate %', Icons.percent)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCalcField(tenureCtrl, 'Months', Icons.calendar_month)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Calculate', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  if (emi > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          _resultRow('Monthly EMI', currencyFormat.format(emi), AppColors.primary),
                          const SizedBox(height: 10),
                          _resultRow('Total Payable', currencyFormat.format(totalPayable), Colors.white70),
                          const SizedBox(height: 10),
                          _resultRow('Total Interest', currencyFormat.format(totalInterest), Colors.orangeAccent),
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
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Apply for Loan', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField(titleCtrl, 'Loan Title'),
                  const SizedBox(height: 10),
                  _buildDialogField(bankCtrl, 'Bank Name'),
                  const SizedBox(height: 10),
                  _buildDialogField(amountCtrl, 'Principal Amount (₹)', isNumber: true),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildDialogField(rateCtrl, 'Rate %', isNumber: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildDialogField(tenureCtrl, 'Months', isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Loan Type',
                      labelStyle: const TextStyle(color: AppColors.textHint),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Personal', 'Home', 'Education', 'Vehicle', 'Business'].map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setDialogState(() => selectedType = val ?? 'Personal'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textHint))),
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
                      SnackBar(content: Text('🎉 ${titleCtrl.text} approved!'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.primary),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          // Additional Loans Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Row(
              children: [
                _headerAction(Icons.calculate_outlined, 'Calculator', () => showEmiCalculator()),
                const SizedBox(width: 10),
                _headerAction(Icons.add_circle_outline, 'New Loan', () => showApplyLoanDialog()),
              ],
            ),
          ),

          // Summary Cards Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Expanded(child: _summaryCard('Total EMI/mo', currencyFormat.format(totalEmi), Icons.payments_outlined, AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Outstanding', currencyFormat.format(totalRemaining), Icons.account_balance_wallet, Colors.orangeAccent)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Expanded(child: _summaryCard('Active Loans', '${loans.length}', Icons.receipt_long, Colors.blueAccent)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Next Due', '$daysToNextDue days', Icons.event, Colors.redAccent)),
              ],
            ),
          ),

          // EMI Distribution Chart
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 30, 25, 15),
            child: Text('EMI Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          if (loans.isNotEmpty)
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 25),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
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
                            Text(e.value.type, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Active Loans
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 30, 25, 15),
            child: Text('Active Loans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...loans.map((loan) => _buildLoanItem(loan, currencyFormat, () => showPayEmiDialog(loan))),

          // Credit Card Utilization
          if (cards.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 30, 25, 15),
              child: Text('Credit Card Utilization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...cards.map((card) => _buildCardUtilizationItem(card, currencyFormat)),
          ],

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ---- Helper Widgets ----

  Widget _headerAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
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
                Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildCalcField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildLoanItem(Loan loan, NumberFormat format, VoidCallback onPayEmi) {
    final daysUntilDue = loan.nextDueDate.difference(DateTime.now()).inDays;
    final isUrgent = daysUntilDue <= 7;
    final isPaid = loan.remainingAmount <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUrgent ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
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
                        Text(loan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (isPaid) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: const Text('PAID', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Text('${loan.bank} • ${loan.interestRate}% p.a.', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${format.format(loan.emi)}/mo', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                  if (!isPaid)
                    Text('Due in $daysUntilDue days', style: TextStyle(color: isUrgent ? Colors.redAccent : Colors.white30, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: loan.progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(isPaid ? AppColors.primary : (isUrgent ? Colors.redAccent : AppColors.primary)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paid: ${format.format(loan.totalAmount - loan.remainingAmount)}', style: const TextStyle(fontSize: 11, color: Colors.white30)),
              Text('Remaining: ${format.format(loan.remainingAmount)}', style: const TextStyle(fontSize: 11, color: Colors.white30)),
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
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

  Widget _buildCardUtilizationItem(CreditCard card, NumberFormat format) {
    final utilization = card.utilization;
    final isHigh = utilization > 50;
    final color = isHigh ? Colors.orange : AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                  Text(card.cardName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Limit: ${format.format(card.limit)}', style: const TextStyle(fontSize: 11, color: Colors.white30)),
              Text('Due: ${format.format(card.balance)}', style: const TextStyle(fontSize: 11, color: Colors.white30)),
            ],
          ),
        ],
      ),
    );
  }
}
