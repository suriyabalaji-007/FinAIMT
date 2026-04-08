import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'package:fin_aimt/core/theme.dart';

class LiveStackedGraph extends ConsumerWidget {
  const LiveStackedGraph({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketData = ref.watch(marketDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!marketData.containsKey('NIFTY50') || !marketData.containsKey('SENSEX')) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final nifty = marketData['NIFTY50']!;
    final sensex = marketData['SENSEX']!;

    // Normalize data for stacking (using percentage change from their own first history point)
    List<FlSpot> niftySpots = [];
    List<FlSpot> sensexSpots = [];

    if (nifty.history.isNotEmpty && sensex.history.isNotEmpty) {
      final niftyBase = nifty.history.first;
      final sensexBase = sensex.history.first;

      for (int i = 0; i < nifty.history.length; i++) {
        final niftyVal = ((nifty.history[i] - niftyBase) / niftyBase) * 100;
        final sensexVal = ((sensex.history[i] - sensexBase) / sensexBase) * 100;
        
        niftySpots.add(FlSpot(i.toDouble(), niftyVal));
        // Stack sensex on top of nifty
        sensexSpots.add(FlSpot(i.toDouble(), niftyVal + sensexVal));
      }
    }

    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: LineChart(
        LineChartData(
          minY: -2,
          maxY: 4,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: (isDark ? Colors.grey.shade900 : Colors.white).withOpacity(0.8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final label = spot.barIndex == 0 ? 'NIFTY' : 'SENSEX';
                  return LineTooltipItem(
                    '$label: ${spot.y.toStringAsFixed(2)}%',
                    TextStyle(color: spot.bar.color, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 10 == 0) {
                    return Text('${value.toInt()}s', style: const TextStyle(color: Colors.grey, fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // SENSEX (Stacked on top, but drawn as a filled area)
            LineChartBarData(
              spots: sensexSpots,
              isCurved: true,
              color: const Color(0xFF3861FB).withOpacity(0.7),
              barWidth: 0,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF3861FB).withOpacity(0.3),
              ),
            ),
            // NIFTY (Base layer)
            LineChartBarData(
              spots: niftySpots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250), // Fast transitions
        curve: Curves.linear,
      ),
    );
  }
}
