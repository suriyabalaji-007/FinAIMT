import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/metrics_provider.dart';

class TaxReportView extends ConsumerWidget {
  const TaxReportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Simulate Individual Tax Computation
    final double grossIncome = metrics.income;
    const double standardDeduction = 50000;
    final double deductions80C = metrics.deductions80C;
    final double taxableIncome = grossIncome - standardDeduction - deductions80C;

    final double incomeTax = metrics.estimatedTax;
    final double healthCess = incomeTax * 0.04;
    final double totalIncomeTax = incomeTax + healthCess;

    const double ltcgTax = 12500;
    const double stcgTax = 8400;
    const double advanceTaxPaid = 50000;
    const double tdsDeducted = 25000;

    final double totalTaxLiability = totalIncomeTax + ltcgTax + stcgTax;
    final double netTaxPayable = totalTaxLiability - advanceTaxPaid - tdsDeducted;

    final textStyleBold = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Individual Tax Report', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context, currencyFormat, netTaxPayable),
            const SizedBox(height: 30),
            
            Text('Income Tax Computation', style: textStyleBold),
            const SizedBox(height: 15),
            _buildTaxSection(context, [
              _buildTaxRow(context, 'Gross Total Income', grossIncome, currencyFormat),
              _buildTaxRow(context, 'Standard Deduction', -standardDeduction, currencyFormat, isDeduction: true),
              _buildTaxRow(context, 'Chapter VI-A (80C, etc)', -deductions80C, currencyFormat, isDeduction: true),
              Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), height: 20),
              _buildTaxRow(context, 'Net Taxable Income', taxableIncome, currencyFormat, isBold: true),
              const SizedBox(height: 15),
              _buildTaxRow(context, 'Computed Income Tax', incomeTax, currencyFormat),
              _buildTaxRow(context, 'Health & Education Cess (4%)', healthCess, currencyFormat),
              Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), height: 20),
              _buildTaxRow(context, 'Total Income Tax', totalIncomeTax, currencyFormat, isBold: true, highlight: true),
            ]),
            
            const SizedBox(height: 30),
            Text('Other Direct Taxes', style: textStyleBold),
            const SizedBox(height: 15),
            _buildTaxSection(context, [
              _buildTaxRow(context, 'Long-Term Capital Gains (LTCG)', ltcgTax, currencyFormat),
              _buildTaxRow(context, 'Short-Term Capital Gains (STCG)', stcgTax, currencyFormat),
              Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), height: 20),
              _buildTaxRow(context, 'Total Direct Tax Liability', totalTaxLiability, currencyFormat, isBold: true),
            ]),

            const SizedBox(height: 30),
            Text('Taxes Paid & TDS', style: textStyleBold),
            const SizedBox(height: 15),
            _buildTaxSection(context, [
              _buildTaxRow(context, 'TDS Deducted', tdsDeducted, currencyFormat),
              _buildTaxRow(context, 'Advance Tax Paid', advanceTaxPaid, currencyFormat),
              Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), height: 20),
              _buildTaxRow(context, 'Net Tax Payable /(Refund)', netTaxPayable, currencyFormat, isBold: true, color: netTaxPayable > 0 ? Colors.redAccent : primaryColor),
            ]),

             const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, NumberFormat format, double netPayable) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    bool isRefund = netPayable <= 0;
    
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (isRefund ? primaryColor : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(isRefund ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: isRefund ? primaryColor : Colors.redAccent),
              ),
              const SizedBox(width: 15),
              Text('Assessment Year 2024-25', 
                style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.6), fontSize: 16)
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(isRefund ? 'Estimated Refund:' : 'Net Tax Payable:', 
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 14)
          ),
          const SizedBox(height: 8),
          Text(format.format(isRefund ? -netPayable : netPayable), 
            style: TextStyle(
              fontSize: 34, 
              fontWeight: FontWeight.bold, 
              color: isRefund ? primaryColor : (isDark ? Colors.white : Colors.black87)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSection(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTaxRow(BuildContext context, String label, double amount, NumberFormat format, {bool isDeduction = false, bool isBold = false, bool highlight = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, 
            style: TextStyle(
              color: isBold ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white70 : Colors.black54), 
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
              fontSize: 14)
            )
          ),
          Text(
            (isDeduction ? '- ' : '') + format.format(amount.abs()),
            style: TextStyle(
              color: color ?? (highlight ? primaryColor : (isBold ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white : Colors.black87))),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
