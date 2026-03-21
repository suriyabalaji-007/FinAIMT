import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AssetDetailView extends ConsumerWidget {
  final String assetId;

  const AssetDetailView({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketData = ref.watch(marketDataProvider);
    final portfolio = ref.watch(dynamicInvestmentsProvider);
    
    final marketAsset = marketData[assetId];
    final investment = portfolio.firstWhere(
      (inv) => inv.assetId == assetId,
      orElse: () => Investment(
        assetId: assetId, 
        name: marketAsset?.name ?? 'Unknown', 
        investedAmount: 0, 
        currentAmount: 0, 
        changePercentage: 0, 
        category: marketAsset?.symbol.contains('BEES') == true ? 'ETFs' : 'Stocks',
      ),
    );

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isUp = investment.changePercentage >= 0;
    final themeColor = isUp ? AppColors.primary : Colors.redAccent;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(investment.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(investment.category, style: const TextStyle(fontSize: 12, color: Colors.white30)),
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
          // Real-time Price Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currencyFormat.format(investment.currentAmount / (investment.quantity > 0 ? investment.quantity : 1)),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${isUp ? '+' : ''}${investment.changePercentage}%',
                  style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Live Scrolling Chart
          SizedBox(
            height: 300,
            width: double.infinity,
            child: _buildLiveChart(investment.history, themeColor),
          ),
          
          const Spacer(),
          
          // Investment Stats
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Invested', currencyFormat.format(investment.investedAmount)),
                    _buildStatItem('Market Value', currencyFormat.format(investment.currentAmount)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Quantity', investment.quantity.toStringAsFixed(2)),
                    _buildStatItem('Avg. Price', currencyFormat.format(investment.averagePrice)),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Trade Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildTradeButton(
                        'SELL', 
                        Colors.redAccent, 
                        () => _showTradeDialog(context, ref, investment, 'sell'),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildTradeButton(
                        'BUY', 
                        AppColors.primary, 
                        () => _showTradeDialog(context, ref, investment, 'buy'),
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

  Widget _buildLiveChart(List<double> history, Color color) {
    if (history.length < 2) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i]));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 59, // Always show a 60-point window
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.surface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '₹${spot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTradeButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  void _showTradeDialog(BuildContext context, WidgetRef ref, Investment inv, String side) {
    final qtyController = TextEditingController(text: '1.0');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final currentPrice = inv.currentAmount / (inv.quantity > 0 ? inv.quantity : 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25,
          right: 25,
          top: 25,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${side.toUpperCase()} ${inv.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white30)),
              ],
            ),
            const SizedBox(height: 10),
            Text('Market Price: ${currencyFormat.format(currentPrice)}', style: const TextStyle(color: Colors.white30)),
            const SizedBox(height: 30),
            TextField(
              controller: qtyController,
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity',
                labelStyle: const TextStyle(color: Colors.white30),
                suffixText: 'UNITS',
                suffixStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final qty = double.tryParse(qtyController.text) ?? 0.0;
                  if (qty <= 0) return;
                  
                  ref.read(userPortfolioProvider.notifier).tradeInvestment(
                    userId: 'USER_1',
                    assetId: inv.assetId,
                    assetName: inv.name,
                    category: inv.category,
                    quantity: qty,
                    price: currentPrice,
                    side: side,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order executed: ${side.toUpperCase()} ${qty.toStringAsFixed(2)} ${inv.name}'),
                      backgroundColor: side == 'buy' ? AppColors.primary : Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: side == 'buy' ? AppColors.primary : Colors.redAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('CONFIRM ${side.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
