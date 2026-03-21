import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/widgets/fin_widgets.dart';
import 'package:intl/intl.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'package:fin_aimt/data/providers/metrics_provider.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/widgets/obscured_balance_widget.dart';
import 'package:fin_aimt/widgets/global_header.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeDashboardView extends ConsumerWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeData = ref.watch(financeDataProvider);
    final marketData = ref.watch(marketDataProvider);
    final accounts = financeData.accounts;
    final cards = financeData.creditCards;
    final transactions = financeData.transactions;
    final insights = financeData.insights;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    void showMockAction(String action) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action functionality coming soon!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.highlight,
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const GlobalHeader(),

          // Market Overview
          if (marketData.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 10, 25, 10),
              child: Text('Market Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: marketData.length,
                itemBuilder: (context, index) {
                  final asset = marketData.values.elementAt(index);
                  return _buildMarketCard(asset, currencyFormat);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Hollycard Balance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hollycard Balance', 
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                const SizedBox(height: 12),
                ObscuredBalanceWidget(
                  balance: financeData.totalBalance,
                  textStyle: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1),
                  isHeader: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Main Actions Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuickAction(icon: Icons.account_balance, label: 'Banking', color: Colors.blueAccent, onTap: () => ref.read(currentTabProvider.notifier).setTab(1)),
                    QuickAction(icon: Icons.trending_up, label: 'Invest', color: AppColors.primary, onTap: () => ref.read(currentTabProvider.notifier).setTab(2)),
                    QuickAction(icon: Icons.security, label: 'Insurance', color: Colors.orangeAccent, onTap: () {
                      ref.read(currentTabProvider.notifier).setTab(2);
                      // In a real app, we'd navigate to the insurance tab specifically
                    }),
                    QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Loans', color: Colors.purpleAccent, onTap: () => ref.read(currentTabProvider.notifier).setTab(3)),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuickAction(icon: Icons.receipt_long_outlined, label: 'Tax & Exp', color: Colors.redAccent, onTap: () => ref.read(currentTabProvider.notifier).setTab(4)),
                    QuickAction(icon: Icons.layers_outlined, label: 'ETFs', color: Colors.tealAccent, onTap: () => ref.read(currentTabProvider.notifier).setTab(2)),
                    QuickAction(icon: Icons.cottage_outlined, label: 'Post Office', color: Colors.brown, onTap: () => ref.read(currentTabProvider.notifier).setTab(2)),
                    QuickAction(icon: Icons.more_horiz, label: 'More', color: Colors.grey, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),

          // AI Insights
          if (insights.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: Text('AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: insights.length,
                itemBuilder: (context, index) => _buildInsightCard(insights[index], () => ref.read(currentTabProvider.notifier).setTab(5)),
              ),
            ),
          ],

          // Bank Accounts Scroll
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
            child: Text('My Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: accounts.length,
              itemBuilder: (context, index) => BalanceCard(
                account: accounts[index],
                onTap: () => showMockAction('${accounts[index].bankName} Details'),
              ),
            ),
          ),

          // Credit Cards
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
            child: Text('Credit Cards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              itemBuilder: (context, index) => _buildCreditCardItem(cards[index], currencyFormat, () => showMockAction(cards[index].cardName)),
            ),
          ),

          // Recent Activity Section
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activity', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => ref.read(currentTabProvider.notifier).setTab(3),
                  child: const Text('View All', 
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 5 ? 5 : transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => TransactionTile(
              transaction: transactions[index],
              onTap: () => showMockAction('Transaction Details'),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMarketCard(MarketData asset, NumberFormat format) {
    final isPositive = asset.priceChange >= 0;
    final color = isPositive ? AppColors.primary : Colors.redAccent;

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(asset.name, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(format.format(asset.currentPrice), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: color, size: 16),
              const SizedBox(width: 4),
              Text('${isPositive ? '+' : ''}${asset.changePercentage.toStringAsFixed(2)}%', 
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(AIInsight insight, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: insight.type == InsightType.warning ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: insight.type == InsightType.warning ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              insight.type == InsightType.warning ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
              color: insight.type == InsightType.warning ? Colors.orange : Colors.blue,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(insight.message, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardItem(CreditCard card, NumberFormat format, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: card.type == 'Visa' 
            ? const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43)])
            : const LinearGradient(colors: [Color(0xFF373B44), Color(0xFF4286f4)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(card.cardName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Icon(Icons.credit_card, color: Colors.white70),
              ],
            ),
            const Spacer(),
            Text(card.cardNumber, style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 2)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BALANCE', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text(format.format(card.balance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DUE DATE', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text(DateFormat('dd MMM').format(card.dueDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
