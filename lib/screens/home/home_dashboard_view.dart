import 'package:flutter/material.dart';
import 'package:fin_aimt/screens/investments/insurance_plans_view.dart';
import 'package:fin_aimt/screens/investments/post_office_schemes_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/widgets/fin_widgets.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'package:fin_aimt/widgets/obscured_balance_widget.dart';
import 'package:fin_aimt/widgets/global_header.dart';

import 'package:fin_aimt/widgets/live_stacked_graph.dart';

class HomeDashboardView extends ConsumerWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeData = ref.watch(financeDataProvider);
    final marketData = ref.watch(marketDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? Colors.white : LightColors.textPrimary;
    final textSecondary = isDark ? Colors.white70 : LightColors.textSecondary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const GlobalHeader(showLogo: true),

          // Market Overview Section (Horizontal Indices)
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 15),
            child: Text('Market Overview', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                if (marketData.containsKey('NIFTY50'))
                  _buildIndexCard(context, 'NIFTY 50', marketData['NIFTY50']!),
                if (marketData.containsKey('SENSEX'))
                  _buildIndexCard(context, 'SENSEX', marketData['SENSEX']!),
                if (marketData.containsKey('RELIANCE'))
                  _buildIndexCard(context, 'Reliance', marketData['RELIANCE']!),
              ],
            ),
          ),

          // Balance Section
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 25, 10),
            child: Text('Hollycard Balance', 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary)
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: ObscuredBalanceWidget(
              balance: financeData.totalBalance,
              textStyle: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                color: isDark ? primaryColor : LightColors.primary
              ),
              isHeader: true,
            ),
          ),

          // Grid Actions (8 items as per Image)
          Padding(
            padding: const EdgeInsets.all(25),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 25,
              children: [
                QuickAction(icon: Icons.account_balance, label: 'Banking', color: Colors.blue, onTap: () => ref.read(currentTabProvider.notifier).setTab(1)),
                QuickAction(icon: Icons.trending_up, label: 'Invest', color: Colors.green, onTap: () => ref.read(currentTabProvider.notifier).setTab(2)),
                QuickAction(icon: Icons.security, label: 'Insurance', color: Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsurancePlansView()))),
                QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Loans', color: Colors.orange, onTap: () => ref.read(currentTabProvider.notifier).setTab(3)),
                QuickAction(icon: Icons.receipt_long, label: 'Tax & Exp', color: Colors.red, onTap: () => ref.read(currentTabProvider.notifier).setTab(4)),
                QuickAction(icon: Icons.layers_outlined, label: 'ETFs', color: Colors.cyan, onTap: () => ref.read(currentTabProvider.notifier).setTab(2)),
                QuickAction(icon: Icons.store_mall_directory_outlined, label: 'Post Office', color: Colors.brown, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostOfficeSchemesView()))),
                QuickAction(icon: Icons.more_horiz, label: 'More', color: Colors.grey, onTap: () {}),
              ],
            ),
          ),

          // Live Index Trends (NEW)
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Real-time Growth (NIFTY + SENSEX)', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 8),
                      SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25),
            child: LiveStackedGraph(),
          ),

          // Planner & Expenses
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Planner & Expenses', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)
                ),
                TextButton(
                  onPressed: () => ref.read(currentTabProvider.notifier).setTab(4),
                  child: Text('View All', style: TextStyle(color: primaryColor)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Expanded(child: _buildExpenseMiniCard(context, 'Monthly Expenses', '₹32,450.00', 'spent of ₹50,000 limit', Icons.pie_chart, Colors.redAccent)),
                const SizedBox(width: 15),
                Expanded(child: _buildExpenseMiniCard(context, 'House Fund', '₹12,50,000', 'saved of ₹50,00,000', Icons.home, Colors.greenAccent)),
              ],
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildIndexCard(BuildContext context, String title, MarketData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUp = data.changePercentage >= 0;
    final color = isUp ? (isDark ? AppColors.primary : const Color(0xFF00B365)) : Colors.redAccent;
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white54 : LightColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('₹${data.currentPrice.toStringAsFixed(2)}', 
            style: TextStyle(color: isDark ? Colors.white : LightColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isUp ? Icons.trending_up : Icons.trending_down, color: color, size: 14),
              const SizedBox(width: 4),
              Text('${isUp ? '+' : ''}${data.changePercentage.toStringAsFixed(2)}%', 
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseMiniCard(BuildContext context, String title, String amount, String subtitle, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: isDark ? Colors.white70 : LightColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const Spacer(),
          Text(amount, 
            style: TextStyle(color: isDark ? Colors.white : LightColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text(subtitle, 
            style: TextStyle(color: isDark ? Colors.white30 : LightColors.textHint, fontSize: 10)
          ),
        ],
      ),
    );
  }
}
