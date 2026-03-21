import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:intl/intl.dart';
import 'package:fin_aimt/widgets/global_header.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fin_aimt/screens/investments/widgets/asset_detail_view.dart';
import 'package:fin_aimt/screens/investments/market_dashboard_view.dart';

class InvestmentsView extends ConsumerWidget {
  const InvestmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref.watch(dynamicInvestmentsProvider);
    final marketData = ref.watch(marketDataProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    double totalInvested = investments.fold(0, (sum, inv) => sum + inv.investedAmount);
    double totalCurrent = investments.fold(0, (sum, inv) => sum + inv.currentAmount);
    double totalProfit = totalCurrent - totalInvested;

    void showTradeDialog(Investment inv, String side) {
      final qtyController = TextEditingController(text: '1');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${side.toUpperCase()} ${inv.name}', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Price: ${currencyFormat.format(inv.currentAmount / (inv.quantity > 0 ? inv.quantity : 1))}', 
                style: const TextStyle(color: AppColors.textHint)),
              const SizedBox(height: 20),
              TextField(
                controller: qtyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Quantity', 
                  labelStyle: TextStyle(color: AppColors.textHint),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textHint))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: side == 'buy' ? AppColors.primary : Colors.redAccent),
              onPressed: () {
                final qty = double.tryParse(qtyController.text) ?? 1;
                ref.read(userPortfolioProvider.notifier).tradeInvestment(
                  userId: 'USER_ID',
                  assetId: inv.assetId,
                  assetName: inv.name,
                  category: inv.category,
                  quantity: qty,
                  price: inv.currentAmount / (inv.quantity > 0 ? inv.quantity : 1),
                  side: side,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${side == 'buy' ? 'Bought' : 'Sold'} ${qtyController.text} units of ${inv.name}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: side == 'buy' ? AppColors.primary : Colors.redAccent,
                  ),
                );
              },
              child: Text(side.toUpperCase(), style: const TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
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
              Container(
                margin: const EdgeInsets.only(right: 25, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('LIVE', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          // Kite-style Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: const TabBar(
              dividerColor: Colors.transparent,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white54,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(text: 'PORTFOLIO'),
                Tab(text: 'MARKET'),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              children: [
                // Portfolio Tab
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      // Investment Summary
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 25),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Portfolio Value', style: TextStyle(color: Colors.white30, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(currencyFormat.format(totalCurrent), 
                                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (totalProfit >= 0 ? AppColors.primary : Colors.redAccent).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${totalProfit >= 0 ? '+' : ''}${((totalProfit / (totalInvested > 0 ? totalInvested : 1)) * 100).toStringAsFixed(1)}%', 
                                    style: TextStyle(color: totalProfit >= 0 ? AppColors.primary : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem('Invested', currencyFormat.format(totalInvested), Colors.white54),
                                _buildSummaryItem('Net P&L', currencyFormat.format(totalProfit), totalProfit >= 0 ? AppColors.primary : Colors.redAccent),
                              ],
                            ),
                            const SizedBox(height: 25),
                            const Text('Asset Allocation', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildAllocationChip('Stocks', investments, currencyFormat),
                                  _buildAllocationChip('ETFs', investments, currencyFormat),
                                  _buildAllocationChip('Mutual Funds', investments, currencyFormat),
                                  _buildAllocationChip('Govt Schemes', investments, currencyFormat),
                                  _buildAllocationChip('Insurance', investments, currencyFormat),
                                  _buildAllocationChip('Gold', investments, currencyFormat),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Portfolio Trend
                      const Padding(
                        padding: EdgeInsets.fromLTRB(25, 30, 25, 15),
                        child: Text('Portfolio Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        height: 160,
                        margin: const EdgeInsets.symmetric(horizontal: 25),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: _buildPortfolioChart(investments),
                      ),

                      // Asset Classes
                      const Padding(
                        padding: EdgeInsets.fromLTRB(25, 30, 25, 15),
                        child: Text('Holdings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      ...investments.map((inv) => GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssetDetailView(assetId: inv.assetId))),
                        child: _buildInvestmentTile(inv, currencyFormat, 
                          () => showTradeDialog(inv, 'buy'),
                          () => showTradeDialog(inv, 'sell'),
                        ),
                      )),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
                
                // Market Tab
                const MarketDashboardView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioChart(List<Investment> investments) {
    // Aggregate all history into a combined portfolio value series
    if (investments.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.white30)));
    }

    // Use the longest history as the x-axis
    final maxLen = investments.fold<int>(0, (max, inv) => inv.history.length > max ? inv.history.length : max);
    if (maxLen < 2) return const Center(child: Text('Loading...', style: TextStyle(color: Colors.white30)));

    final spots = <FlSpot>[];
    for (int i = 0; i < maxLen; i++) {
      double total = 0;
      for (final inv in investments) {
        if (i < inv.history.length) {
          total += inv.history[i] * inv.quantity;
        } else if (inv.history.isNotEmpty) {
          total += inv.history.last * inv.quantity;
        }
      }
      spots.add(FlSpot(i.toDouble(), total));
    }

    final isUp = spots.length > 1 && spots.last.y >= spots.first.y;
    final lineColor = isUp ? AppColors.primary : Colors.redAccent;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true, 
              gradient: LinearGradient(
                colors: [lineColor.withOpacity(0.2), lineColor.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistChip(MarketData asset, NumberFormat format) {
    final isPositive = asset.priceChange >= 0;
    final color = isPositive ? AppColors.primary : Colors.redAccent;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(asset.name, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(format.format(asset.currentPrice), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: color, size: 18),
              Text('${isPositive ? '+' : ''}${asset.changePercentage.toStringAsFixed(2)}%', 
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildAllocationChip(String category, List<Investment> investments, NumberFormat format) {
    final catInvestments = investments.where((inv) => inv.category == category).toList();
    final total = catInvestments.fold(0.0, (sum, inv) => sum + inv.currentAmount);
    
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(_getCategoryIcon(category), size: 12, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(category, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(format.format(total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInvestmentTile(Investment inv, NumberFormat format, VoidCallback onBuy, VoidCallback onSell) {
    final pricePerUnit = inv.quantity > 0 ? inv.currentAmount / inv.quantity : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getCategoryIcon(inv.category), color: Colors.white70),
                    ),
                    const SizedBox(width: 15),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                          Text('${inv.category} • ${inv.quantity.toStringAsFixed(1)} units', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _LivePriceText(price: inv.currentAmount, format: format),
                  Text('${inv.changePercentage > 0 ? '+' : ''}${inv.changePercentage}%', 
                    style: TextStyle(color: inv.changePercentage > 0 ? AppColors.primary : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onBuy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSell,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
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
      case 'Govt Schemes': return Icons.account_balance;
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

  const _LivePriceText({required this.price, required this.format});

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
    final isUp = _previousPrice == null || widget.price >= _previousPrice!;
    final flashColor = isUp ? AppColors.primary : Colors.redAccent;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: _flashing ? flashColor : Colors.white,
      ),
      child: Text(widget.format.format(widget.price)),
    );
  }
}
