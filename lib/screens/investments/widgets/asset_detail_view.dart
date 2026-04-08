import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/widgets/unified_payment_flow.dart';
import 'package:fin_aimt/screens/investments/transaction_history_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AssetDetailView extends ConsumerStatefulWidget {
  final String assetId;
  const AssetDetailView({super.key, required this.assetId});

  @override
  ConsumerState<AssetDetailView> createState() => _AssetDetailViewState();
}

class _AssetDetailViewState extends ConsumerState<AssetDetailView> {
  String _selectedTime = '1D';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketData = ref.watch(marketDataProvider);
    final portfolio = ref.watch(dynamicInvestmentsProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white30 : Colors.black54;

    final marketAsset = marketData[widget.assetId];
    final investment = portfolio.firstWhere(
      (inv) => inv.assetId == widget.assetId,
      orElse: () => Investment(
        assetId: widget.assetId, 
        name: marketAsset?.name ?? 'Unknown', 
        investedAmount: 0, 
        currentAmount: 0, 
        changePercentage: marketAsset?.changePercentage ?? 0, 
        category: marketAsset?.category ?? 'Stocks',
      ),
    );

    if (marketAsset == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isUp = marketAsset.changePercentage >= 0;
    final themeColor = isUp ? AppColors.primary : Colors.redAccent;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(marketAsset.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            Text(marketAsset.category, style: TextStyle(fontSize: 12, color: textSubColor)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('LIVE', style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currencyFormat.format(marketAsset.currentPrice),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  '${isUp ? '+' : ''}${marketAsset.changePercentage.toStringAsFixed(2)}%',
                  style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          Padding(
            padding: const EdgeInsets.only(right: 15, left: 5),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: _buildLiveChart(marketAsset.history, themeColor, isDark),
            ),
          ),
          
          const SizedBox(height: 15),
          _buildTimeSelector(isDark),
          
          const Spacer(),
          
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -4))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Invested', currencyFormat.format(investment.investedAmount), isDark),
                    _buildStatItem('Market Value', currencyFormat.format(investment.currentAmount), isDark),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Quantity', investment.quantity.toStringAsFixed(2), isDark),
                    _buildStatItem('Avg. Price', currencyFormat.format(investment.averagePrice), isDark),
                  ],
                ),
                const SizedBox(height: 30),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildTradeButton(
                        'SELL', 
                        Colors.redAccent, 
                        () => _showTradeDialog(context, ref, investment.copyWith(name: marketAsset.name, currentAmount: investment.currentAmount), 'sell'),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildTradeButton(
                        'BUY', 
                        AppColors.primary, 
                        () => _showTradeDialog(context, ref, investment.copyWith(name: marketAsset.name, currentAmount: marketAsset.currentPrice), 'buy'),
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChart(List<double> realHistory, Color color, bool isDark) {
    List<double> history = realHistory;
    
    if (_selectedTime != '1D' && realHistory.isNotEmpty) {
      final basePrice = realHistory.last;
      int points = _selectedTime == '1W' ? 100 : _selectedTime == '1M' ? 150 : 200;
      history = List.generate(points, (i) {
        final offset = points - i;
        return basePrice * (1.0 - (offset * 0.001) + (0.05 * (i % 5 == 0 ? 1 : -1)));
      });
      history.add(basePrice);
    }

    if (history.length < 2) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i]));
    }

    final maxXVal = history.length - 1.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxXVal,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100, 
          getDrawingHorizontalLine: (value) => FlLine(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxXVal > 60 ? (maxXVal / 5) : 15,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                if (value >= maxXVal) return const SizedBox.shrink();
                
                String label;
                if (_selectedTime == '1D') {
                  final secondsAgo = maxXVal - value.toInt();
                  final time = DateTime.now().subtract(Duration(seconds: secondsAgo.toInt()));
                  label = DateFormat('HH:mm:ss').format(time);
                } else {
                  final daysAgo = maxXVal - value.toInt();
                  final date = DateTime.now().subtract(Duration(days: daysAgo.toInt()));
                  label = DateFormat('MMM dd').format(date);
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(color: isDark ? Colors.white30 : Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: isDark ? AppColors.surface : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '₹${spot.y.toStringAsFixed(2)}',
                  TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(bool isDark) {
    final times = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: times.map((t) {
          final isSelected = t == _selectedTime;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _selectedTime = t;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white30 : Colors.black54),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white30 : Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTradeButton(String label, Color color, VoidCallback onTap, bool isDark) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  void _showTradeDialog(BuildContext context, WidgetRef ref, Investment inv, String side) {
    if (side == 'sell') {
      _showSellDialog(context, ref, inv);
      return;
    }
    UnifiedPaymentFlow.show(
      context: context,
      ref: ref,
      assetName: inv.name,
      category: inv.category.isEmpty ? 'Stocks' : inv.category,
      quantity: 1,
      pricePerUnit: inv.currentAmount > 0 ? inv.currentAmount : 1,
      side: side,
    );
  }

  void _showSellDialog(BuildContext context, WidgetRef ref, Investment inv) {
    final qtyController = TextEditingController(text: '1.0');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
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
}
