import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fin_aimt/data/providers/metrics_provider.dart';
import 'package:fin_aimt/widgets/global_header.dart';
import 'package:fin_aimt/screens/expenses/tax_report_view.dart';

class ExpensesView extends ConsumerWidget {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    Color getCategoryColor(String category) {
      switch (category) {
        case 'Food': return Colors.orange;
        case 'Bills': return Colors.blue;
        case 'Rent': return Colors.purple;
        case 'Entertainment': return Colors.cyan;
        case 'Shopping': return Colors.pinkAccent;
        default: return Colors.grey;
      }
    }

    void handleTaxAction(String taxType) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                ),
                const SizedBox(width: 20),
                Expanded(child: Text('Connecting to $taxType portal...', 
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)
                )),
              ],
            ),
          );
        },
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        Navigator.pop(context); // close connecting
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (context) => _buildTaxInteractiveSheet(taxType, currencyFormat, context),
        );
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlobalHeader(
              title: 'Tax',
              subtitle: 'Analytics & Management',
              showLogo: false,
            ),

            // Tax Analytics Section
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
              child: Text('Tax Analytics', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TaxReportView()));
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Est. Tax Payable (2024-25)', 
                              style: TextStyle(color: isDark ? Colors.white30 : Colors.black45, fontSize: 12)
                            ),
                            const SizedBox(height: 8),
                            Text(currencyFormat.format(metrics.estimatedTax), 
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87, 
                                fontSize: 24, 
                                fontWeight: FontWeight.bold
                              )
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.receipt_long_outlined, color: primaryColor),
                        ),
                      ],
                    ),
                    Divider(height: 40, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTaxInfo(context, 'Income', currencyFormat.format(metrics.income)),
                        _buildTaxInfo(context, '80C Save', currencyFormat.format(metrics.deductions80C)),
                        _buildTaxInfo(context, 'Taxable', currencyFormat.format(metrics.income - metrics.deductions80C)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tax Services Section
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
              child: Text('Tax Services', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTaxServiceCard(context, 'Home Tax', Icons.home_work_outlined, Colors.blueAccent, () => handleTaxAction('Home Tax')),
                  _buildTaxServiceCard(context, 'Water Tax', Icons.water_drop_outlined, Colors.cyan, () => handleTaxAction('Water Tax')),
                  _buildTaxServiceCard(context, 'TDS Claim', Icons.account_balance_wallet_outlined, primaryColor, () => handleTaxAction('TDS Claim')),
                  _buildTaxServiceCard(context, 'Other Tax', Icons.receipt_long, Colors.orange, () => handleTaxAction('Other Tax')),
                ],
              ),
            ),

            // Expense Breakdown Chart
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
              child: Text('Expense Breakdown', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
              ),
            ),
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 25),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color, 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
                ],
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
                          final style = TextStyle(color: isDark ? AppColors.textHint : LightColors.textHint, fontSize: 10);
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
                          color: getCategoryColor(e.key), 
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

  Widget _buildTaxInfo(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildTaxServiceCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(title, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxInteractiveSheet(String taxType, NumberFormat format, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    double amount = taxType == 'Home Tax' ? 12500 : taxType == 'Water Tax' ? 1800 : taxType == 'TDS Claim' ? 45000 : 5000;
    bool isClaim = taxType.contains('Claim');

    return Container(
      padding: const EdgeInsets.fromLTRB(30,30,30,50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$taxType ${isClaim ? 'Status' : 'Bill'}', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(isClaim ? 'Estimated Refund Available:' : 'Outstanding Amount Due:', 
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)
          ),
          const SizedBox(height: 8),
          Text(format.format(amount), 
            style: TextStyle(
              fontSize: 36, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : Colors.black87, 
              letterSpacing: -1
            )
          ),
          const SizedBox(height: 35),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isClaim ? 'TDS Claim process initiated successfully.' : '$taxType payment processed automatically.'),
                    backgroundColor: isClaim ? primaryColor : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isClaim ? primaryColor : Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isClaim ? 'CLAIM NOW' : 'PAY SECURELY', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
          )
        ],
      ),
    );
  }
}
