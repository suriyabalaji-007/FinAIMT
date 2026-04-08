import 'package:flutter/material.dart';
import 'package:fin_aimt/screens/investments/insurance_plans_view.dart';
import 'package:fin_aimt/screens/investments/post_office_schemes_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/data/repositories/mock_repository.dart';
import 'package:fin_aimt/screens/investments/widgets/asset_detail_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MarketDashboardView extends ConsumerStatefulWidget {
  const MarketDashboardView({super.key});

  @override
  ConsumerState<MarketDashboardView> createState() => _MarketDashboardViewState();
}

class _MarketDashboardViewState extends ConsumerState<MarketDashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketData = ref.watch(marketDataProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? Colors.white : LightColors.textPrimary;
    final textSecondary = isDark ? Colors.white54 : LightColors.textSecondary;
    
    // Extract Indices
    final nifty = marketData['NIFTY50'];
    final sensex = marketData['SENSEX'];
    
    final stocks = marketData.values.where((data) => 
      data.category == 'Stocks' &&
      (data.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) || 
       data.name.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();

    final etfs = marketData.values.where((data) => 
      data.category == 'ETFs' &&
      (data.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) || 
       data.name.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();

    final mutualFunds = marketData.values.where((data) => 
      data.category == 'Mutual Funds' &&
      (data.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) || 
       data.name.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();

    final posSchemes = MockRepository.getPostOfficeSchemes().where((scheme) => 
      scheme.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      scheme.id.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    final insuranceProducts = MockRepository.getInsuranceProducts().where((p) => 
      p.planName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      p.provider.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Sticky Indices Header (Kite Style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05))),
            ),
            child: Row(
              children: [
                if (nifty != null) Expanded(child: _buildIndexCard(context, 'NIFTY 50', nifty, currencyFormat)),
                const SizedBox(width: 15),
                if (sensex != null) Expanded(child: _buildIndexCard(context, 'SENSEX', sensex, currencyFormat)),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search (Reliance, Nifty Bees, Health...)',
                hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: textSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Category TabBar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: textSecondary,
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'STOCKS'),
              Tab(text: 'ETFS'),
              Tab(text: 'MUTUAL FUNDS'),
              Tab(text: 'POST OFFICE'),
              Tab(text: 'INSURANCE'),
            ],
          ),
          
          // Market List (TabBarView)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMarketList(context, stocks, currencyFormat),
                _buildMarketList(context, etfs, currencyFormat),
                _buildMarketList(context, mutualFunds, currencyFormat),
                _buildPosList(context, posSchemes, currencyFormat),
                _buildInsuranceList(context, insuranceProducts, currencyFormat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketList(BuildContext context, List<MarketData> items, NumberFormat format) {
    if (items.isEmpty) return _buildEmptyState(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildMarketRow(context, items[index], format),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text('No results found', style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.2))),
    );
  }

  Widget _buildPosList(BuildContext context, List<PostOfficeScheme> schemes, NumberFormat format) {
    if (schemes.isEmpty) return _buildEmptyState(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textSecondary = isDark ? Colors.white54 : LightColors.textSecondary;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: schemes.length,
      itemBuilder: (context, index) {
        final scheme = schemes[index];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostOfficeSchemesView())),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scheme.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : LightColors.textPrimary)),
                      Text('${scheme.type} • ${scheme.tenureYears} Years', style: TextStyle(color: textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${scheme.interestRate}%', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Interest', style: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPosDepositDialog(PostOfficeScheme scheme, NumberFormat format) {
    final amountController = TextEditingController(text: scheme.minInvestment.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          left: 25,
          right: 25,
          top: 25,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Open Post Office Scheme', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : LightColors.textPrimary)
            ),
            const SizedBox(height: 8),
            Text(scheme.name, style: TextStyle(color: isDark ? Colors.white70 : LightColors.textSecondary)),
            const SizedBox(height: 30),
            TextField(
              controller: amountController,
              autofocus: true,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : LightColors.textPrimary),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Investment Amount',
                labelStyle: TextStyle(color: isDark ? Colors.white30 : LightColors.textHint),
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: isDark ? Colors.white : LightColors.textPrimary, fontSize: 24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount < scheme.minInvestment) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Minimum investment is ${format.format(scheme.minInvestment)}')),
                    );
                    return;
                  }
                  
                  ref.read(userPortfolioProvider.notifier).tradeInvestment(
                    assetId: scheme.id,
                    assetName: scheme.name,
                    category: 'Post Office Schemes',
                    quantity: 1,
                    price: amount,
                    side: 'buy',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully opened ${scheme.name} with ${format.format(amount)}'),
                      backgroundColor: primaryColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CONFIRM DEPOSIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceList(BuildContext context, List<InsuranceProduct> products, NumberFormat format) {
    if (products.isEmpty) return _buildEmptyState(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textSecondary = isDark ? Colors.white54 : LightColors.textSecondary;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    child: Text(product.provider[0], style: TextStyle(color: isDark ? Colors.white : LightColors.textPrimary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.planName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : LightColors.textPrimary)),
                        Text(product.provider, style: TextStyle(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.type,
                      style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sum Insured', style: TextStyle(color: textSecondary, fontSize: 11)),
                      Text(format.format(product.sumInsured), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : LightColors.textPrimary)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Annual Premium', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(format.format(product.annualPremium), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsurancePlansView())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Compare & Buy', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInsurancePurchaseConfirmation(InsuranceProduct product, NumberFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

     showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm Purchase', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : LightColors.textPrimary)
            ),
            const SizedBox(height: 8),
            Text('You are buying ${product.planName} from ${product.provider}.', style: TextStyle(color: isDark ? Colors.white70 : LightColors.textSecondary)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Premium Amount:', style: TextStyle(color: isDark ? Colors.white54 : LightColors.textSecondary)),
                Text(format.format(product.annualPremium), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ref.read(userPortfolioProvider.notifier).tradeInvestment(
                  assetId: product.id,
                  assetName: product.planName,
                  category: 'Insurance',
                  quantity: 1,
                  price: product.annualPremium,
                  side: 'buy',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Purchase of ${product.planName} successful!'),
                    backgroundColor: primaryColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Pay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexCard(BuildContext context, String label, MarketData data, NumberFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUp = data.changePercentage >= 0;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final color = isUp ? primaryColor : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : LightColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(data.currentPrice.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : LightColors.textPrimary)),
            const SizedBox(width: 6),
            Text(
              '${isUp ? '+' : ''}${data.priceChange.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarketRow(BuildContext context, MarketData stock, NumberFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isUp = stock.changePercentage >= 0;
    final color = isUp ? primaryColor : Colors.redAccent;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssetDetailView(assetId: stock.symbol))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.03))),
        ),
        child: Row(
          children: [
            // Symbol & Name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.symbol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : LightColors.textPrimary)),
                  Text(stock.name, style: TextStyle(color: isDark ? Colors.white24 : LightColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            
            // Mini Sparkline
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 30,
                child: _buildSparkline(stock.history, color),
              ),
            ),
            
            // Price & Change
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(format.format(stock.currentPrice), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : LightColors.textPrimary)),
                  Text(
                    '${isUp ? '+' : ''}${stock.changePercentage.toStringAsFixed(2)}%',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkline(List<double> history, Color color) {
    if (history.length < 2) return const SizedBox();
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i]));
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color.withOpacity(0.5),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

