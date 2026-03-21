import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fin_aimt/data/providers/metrics_provider.dart';
import 'package:fin_aimt/widgets/fin_widgets.dart';
import 'package:fin_aimt/widgets/global_header.dart';

class ExpensesView extends ConsumerWidget {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);
    final financeData = ref.watch(financeDataProvider);
    final transactions = financeData.transactions;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    Color _getCategoryColor(String category) {
      switch (category) {
        case 'Food': return Colors.orange;
        case 'Bills': return Colors.blue;
        case 'Rent': return Colors.purple;
        case 'Entertainment': return Colors.cyan;
        case 'Shopping': return Colors.pinkAccent;
        default: return Colors.grey;
      }
    }

    void showMockAction(String action) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Viewing $action details...'), behavior: SnackBarBehavior.floating),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlobalHeader(
              title: 'Expenses',
              subtitle: 'Analytics & Tax',
              showLogo: false,
            ),
            // Statistic Summary Card
            Container(
              margin: const EdgeInsets.all(25),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Statistic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Text('Monthly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildIndicator(AppColors.primary, 'Income'),
                      const SizedBox(width: 20),
                      _buildIndicator(Colors.white30, 'Expenses'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 600,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                if (value.toInt() < months.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(months[value.toInt()], style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              getTitlesWidget: (value, meta) {
                                return Text('₹${value.toInt()}', style: const TextStyle(color: AppColors.textHint, fontSize: 10));
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _buildBarGroup(0, 450, 310),
                          _buildBarGroup(1, 380, 240),
                          _buildBarGroup(2, 520, 410),
                          _buildBarGroup(3, 410, 280),
                          _buildBarGroup(4, 490, 350),
                          _buildBarGroup(5, 540, 420),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Income / Expense Summary Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Income', 
                      currencyFormat.format(metrics.income), 
                      Icons.arrow_downward_rounded,
                      AppColors.surface,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildSummaryCard(
                      'Expense', 
                      currencyFormat.format(metrics.expense), 
                      Icons.arrow_upward_rounded,
                      AppColors.primary,
                      Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Transactions Section
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 30, 25, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(Icons.tune_outlined, color: Colors.white70, size: 20),
                ],
              ),
            ),

            ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 5 ? 5 : transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TransactionTile(
                transaction: transactions[index],
                onTap: () => showMockAction('Details'),
              ),
            ),

            // Tax Analytics Section
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 30, 25, 15),
              child: Text('Tax Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            GestureDetector(
              onTap: () => showMockAction('Full Tax Report'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Est. Tax Payable (2024-25)', style: TextStyle(color: Colors.white30, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text(currencyFormat.format(metrics.estimatedTax), 
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const Divider(height: 40, color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTaxInfo('Income', currencyFormat.format(metrics.income)),
                        _buildTaxInfo('80C Save', currencyFormat.format(metrics.deductions80C)),
                        _buildTaxInfo('Taxable', currencyFormat.format(metrics.income - metrics.deductions80C)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expense Breakdown Chart
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 30, 25, 15),
              child: Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 25),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface, 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (metrics.expenseCategories.values.fold(0.0, (m, v) => v > m ? v : m)) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(color: AppColors.textHint, fontSize: 10);
                          final cats = metrics.expenseCategories.keys.toList();
                          if (value.toInt() < cats.length) {
                            return Text(cats[value.toInt()], style: style);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: metrics.expenseCategories.entries.map((e) {
                    final index = metrics.expenseCategories.keys.toList().indexOf(e.key);
                    return BarChartGroupData(
                      x: index, 
                      barRods: [
                        BarChartRodData(
                          toY: e.value, 
                          color: _getCategoryColor(e.key), 
                          width: 20,
                          borderRadius: BorderRadius.circular(6),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: AppColors.primary,
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: y2,
          color: Colors.white.withOpacity(0.1),
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
      barsSpace: 4,
    );
  }

  Widget _buildIndicator(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 12)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String amount, IconData icon, Color bgColor, Color iconColor) {
    final isPrimary = bgColor == AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrimary ? Colors.black.withOpacity(0.1) : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 20),
          Text(label, style: TextStyle(color: isPrimary ? Colors.black54 : Colors.white54, fontSize: 12)),
          const SizedBox(height: 5),
          Text(amount, 
            style: TextStyle(
              color: isPrimary ? Colors.black : Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.bold
            )),
        ],
      ),
    );
  }

  Widget _buildTaxInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
