import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:intl/intl.dart';
import 'package:fin_aimt/widgets/global_header.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fin_aimt/screens/investments/widgets/asset_detail_view.dart';
import 'package:fin_aimt/screens/investments/market_dashboard_view.dart';
import 'package:fin_aimt/screens/investments/insurance_plans_view.dart';
import 'package:fin_aimt/screens/investments/post_office_schemes_view.dart';

import 'package:fin_aimt/screens/investments/transaction_history_view.dart';
import 'package:fin_aimt/widgets/unified_payment_flow.dart';

class InvestmentsView extends ConsumerWidget {
  const InvestmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref.watch(dynamicInvestmentsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    double totalInvested = investments.fold(0, (sum, inv) => sum + inv.investedAmount);
    double totalCurrent = investments.fold(0, (sum, inv) => sum + inv.currentAmount);
    double totalProfit = totalCurrent - totalInvested;

    void showTradeDialog(Investment inv, String side) {
      if (side == 'buy') {
        UnifiedPaymentFlow.show(
          context: context,
          ref: ref,
          assetName: inv.name,
          category: inv.category.isEmpty ? 'Stocks' : inv.category,
          quantity: 1,
          pricePerUnit: inv.currentAmount > 0 ? (inv.currentAmount / (inv.quantity > 0 ? inv.quantity : 1)) : 1000,
          side: side,
        );
        return;
      }
      
      _showSellDialog(context, ref, inv, isDark, primaryColor, currencyFormat);
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          GlobalHeader(
            title: 'Investments',
            subtitle: 'Portfolio & Markets',
            showLogo: false,
            actions: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryView())),
                icon: Icon(Icons.history_rounded, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(width: 10),
            ],
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05))),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelColor: primaryColor,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black38,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'PORTFOLIO'),
                Tab(text: 'MARKET'),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      // Portfolio Value Card
                      Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Portfolio Value', 
                              style: TextStyle(color: isDark ? Colors.white30 : Colors.black45, fontSize: 12)
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(currencyFormat.format(totalCurrent), 
                                    style: TextStyle(
                                      fontSize: 30, 
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87
                                    ),
                                    overflow: TextOverflow.ellipsis),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (totalProfit >= 0 ? primaryColor : Colors.redAccent).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${totalProfit >= 0 ? '+' : ''}${((totalProfit / (totalInvested > 0 ? totalInvested : 1)) * 100).toStringAsFixed(1)}%', 
                                    style: TextStyle(color: totalProfit >= 0 ? primaryColor : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem(context, 'Invested', currencyFormat.format(totalInvested), isDark ? Colors.white54 : Colors.black45),
                                _buildSummaryItem(context, 'Net P&L', currencyFormat.format(totalProfit), totalProfit >= 0 ? primaryColor : Colors.redAccent),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Text('Asset Allocation', 
                              style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildAllocationChip(context, 'Stocks', investments, currencyFormat),
                                  _buildAllocationChip(context, 'ETFs', investments, currencyFormat),
                                  _buildAllocationChip(context, 'Mutual Funds', investments, currencyFormat),
                                  _buildAllocationChip(context, 'Post Office Schemes', investments, currencyFormat),
                                  _buildAllocationChip(context, 'Insurance', investments, currencyFormat),
                                  _buildAllocationChip(context, 'Gold', investments, currencyFormat),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
                        child: Text('Portfolio Trend', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
                        ),
                      ),
                      Container(
                        height: 160,
                        margin: const EdgeInsets.symmetric(horizontal: 25),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                        ),
                        child: _buildPortfolioChart(context, investments),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
                        child: Text('Holdings', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
                        ),
                      ),
                      ...investments.map((inv) => GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssetDetailView(assetId: inv.assetId))),
                        child: _buildInvestmentTile(context, inv, currencyFormat, () => showTradeDialog(inv, 'buy'), () => showTradeDialog(inv, 'sell')),
                      )),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
                const MarketDashboardView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSellDialog(BuildContext context, WidgetRef ref, Investment inv, bool isDark, Color primaryColor, NumberFormat currencyFormat) {
    final qtyController = TextEditingController(text: '1.0');
    final price = inv.currentAmount / (inv.quantity > 0 ? inv.quantity : 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 30, left: 25, right: 25, top: 25),
        decoration: BoxDecoration(color: isDark ? AppColors.surface : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SELL ${inv.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: isDark ? Colors.white30 : Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Price: ${currencyFormat.format(price)}', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
            const SizedBox(height: 20),
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Quantity',
                labelStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black54),
                suffixText: 'UNITS',
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final qty = double.tryParse(qtyController.text) ?? 0;
                  if (qty <= 0) return;
                  ref.read(userPortfolioProvider.notifier).tradeInvestment(
                    assetId: inv.assetId, assetName: inv.name, category: inv.category,
                    quantity: qty, price: price, side: 'sell',
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sold ${qty.toStringAsFixed(2)} units of ${inv.name}'), backgroundColor: Colors.redAccent));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('CONFIRM SELL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioChart(BuildContext context, List<Investment> investments) {
    if (investments.isEmpty) return const Center(child: Text('No data'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final maxLen = investments.fold<int>(0, (max, inv) => inv.history.length > max ? inv.history.length : max);
    if (maxLen < 2) return const Center(child: Text('Loading...'));

    final spots = <FlSpot>[];
    for (int i = 0; i < maxLen; i++) {
      double total = 0;
      for (final inv in investments) {
        if (i < inv.history.length) {
          total += inv.history[i] * inv.quantity;
        } else if (inv.history.isNotEmpty) total += inv.history.last * inv.quantity;
      }
      spots.add(FlSpot(i.toDouble(), total));
    }

    final isUp = spots.length > 1 && spots.last.y >= spots.first.y;
    final lineColor = isUp ? primaryColor : Colors.redAccent;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, color: lineColor, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [lineColor.withOpacity(0.2), lineColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildAllocationChip(BuildContext context, String category, List<Investment> investments, NumberFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final catInvestments = investments.where((inv) => inv.category == category).toList();
    final total = catInvestments.fold(0.0, (sum, inv) => sum + inv.currentAmount);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(_getCategoryIcon(category), size: 12, color: primaryColor),
              const SizedBox(width: 6),
              Text(category, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(format.format(total), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInvestmentTile(BuildContext context, Investment inv, NumberFormat format, VoidCallback onBuy, VoidCallback onSell) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isPostOffice = inv.category == 'Post Office Schemes';
    final profit = inv.currentAmount - inv.investedAmount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Icon(_getCategoryIcon(inv.category), color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(width: 15),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                          Text(isPostOffice ? 'Safe & Guaranteed' : '${inv.category} • ${inv.quantity.toStringAsFixed(1)} units', style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isPostOffice)
                    Text(format.format(inv.currentAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87))
                  else
                    _LivePriceText(price: inv.currentAmount, format: format, isDark: isDark),
                  
                  Text(
                    isPostOffice ? '+${format.format(profit)} Return' : '${inv.changePercentage > 0 ? '+' : ''}${inv.changePercentage}%', 
                    style: TextStyle(color: (isPostOffice || inv.changePercentage > 0) ? (isDark ? AppColors.primary : const Color(0xFF00B365)) : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (isPostOffice)
             Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invested Amount', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10)),
                      Text(format.format(inv.investedAmount), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostOfficeSchemesView())),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor.withOpacity(0.1), foregroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  child: const Text('ADD MORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBuy,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSell,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent, width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: const Text('SELL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Stocks': return Icons.show_chart;
      case 'Mutual Funds': return Icons.pie_chart;
      case 'Post Office Schemes': return Icons.account_balance;
      case 'Gold': return Icons.layers_outlined;
      case 'Insurance': return Icons.security;
      case 'ETFs': return Icons.receipt_long;
      default: return Icons.attach_money;
    }
  }
}

class _LivePriceText extends StatefulWidget {
  final double price;
  final NumberFormat format;
  final bool isDark;

  const _LivePriceText({required this.price, required this.format, required this.isDark});

  @override
  State<_LivePriceText> createState() => _LivePriceTextState();
}

class _LivePriceTextState extends State<_LivePriceText> {
  double? _previousPrice;
  bool _flashing = false;

  @override
  void didUpdateWidget(_LivePriceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.price != widget.price) {
      _previousPrice = oldWidget.price;
      setState(() => _flashing = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _flashing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isUp = _previousPrice == null || widget.price >= _previousPrice!;
    final flashColor = isUp ? primaryColor : Colors.redAccent;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontWeight: FontWeight.bold, fontSize: 14,
        color: _flashing ? flashColor : (widget.isDark ? Colors.white : Colors.black87),
      ),
      child: Text(widget.format.format(widget.price)),
    );
  }
}
