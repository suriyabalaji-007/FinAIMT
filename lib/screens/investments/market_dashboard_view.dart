import 'package:flutter/material.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
    
    // Extract Indices
    final nifty = marketData['NIFTY50'];
    final sensex = marketData['SENSEX'];
    
    // Categorize
    final etfSymbols = MockRepository.getETFs().map((e) => e.symbol).toSet();
    final posIds = MockRepository.getPostOfficeSchemes().map((e) => e.id).toSet();

    final stocks = marketData.values.where((data) => 
      data.symbol != 'NIFTY50' && 
      data.symbol != 'SENSEX' &&
      !etfSymbols.contains(data.symbol) &&
      !posIds.contains(data.symbol) &&
      (data.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) || 
       data.name.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();

    final etfs = marketData.values.where((data) => 
      etfSymbols.contains(data.symbol) &&
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Indices Header (Kite Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  if (nifty != null) Expanded(child: _buildIndexCard('NIFTY 50', nifty, currencyFormat)),
                  const SizedBox(width: 15),
                  if (sensex != null) Expanded(child: _buildIndexCard('SENSEX', sensex, currencyFormat)),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search (Reliance, Nifty Bees, Health...)',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.search, color: Colors.white24),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            // Category TabBar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white54,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'STOCKS'),
                Tab(text: 'ETFS'),
                Tab(text: 'POST OFFICE'),
                Tab(text: 'INSURANCE'),
              ],
            ),
            
            // Market List (TabBarView)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMarketList(stocks, currencyFormat),
                  _buildMarketList(etfs, currencyFormat),
                  _buildPosList(posSchemes, currencyFormat),
                  _buildInsuranceList(insuranceProducts, currencyFormat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketList(List<MarketData> items, NumberFormat format) {
    if (items.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildMarketRow(items[index], format),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('No results found', style: TextStyle(color: Colors.white.withOpacity(0.2))),
    );
  }

  Widget _buildPosList(List<PostOfficeScheme> schemes, NumberFormat format) {
    if (schemes.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: schemes.length,
      itemBuilder: (context, index) {
        final scheme = schemes[index];
        return InkWell(
          onTap: () => _showPosDepositDialog(scheme, format),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scheme.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${scheme.type} • ${scheme.tenureYears} Years', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${scheme.interestRate}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('Interest', style: TextStyle(color: Colors.white24, fontSize: 10)),
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
            const Text('Open Post Office Scheme', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(scheme.name, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 30),
            TextField(
              controller: amountController,
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Investment Amount',
                labelStyle: const TextStyle(color: Colors.white30),
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: Colors.white, fontSize: 24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
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
                    userId: 'USER_1',
                    assetId: scheme.id,
                    assetName: scheme.name,
                    category: 'Govt Schemes',
                    quantity: 1,
                    price: amount,
                    side: 'buy',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully opened ${scheme.name} with ${format.format(amount)}'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CONFIRM DEPOSIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceList(List<InsuranceProduct> products, NumberFormat format) {
    if (products.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white10,
                    child: Text(product.provider[0], style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.planName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(product.provider, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.type,
                      style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
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
                      const Text('Sum Insured', style: TextStyle(color: Colors.white24, fontSize: 11)),
                      Text(format.format(product.sumInsured), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Annual Premium', style: TextStyle(color: Colors.white24, fontSize: 11)),
                      Text(format.format(product.annualPremium), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => _showPurchaseConfirmation(product, format),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPurchaseConfirmation(InsuranceProduct product, NumberFormat format) {
     showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm Purchase', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('You are buying ${product.planName} from ${product.provider}.', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Premium Amount:', style: TextStyle(color: Colors.white54)),
                Text(format.format(product.annualPremium), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ref.read(userPortfolioProvider.notifier).tradeInvestment(
                  userId: 'USER_ID',
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
                    content: Text('Purchase of ${product.planName} from ${product.provider} successful!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirm & Pay', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexCard(String label, MarketData data, NumberFormat format) {
    final isUp = data.changePercentage >= 0;
    final color = isUp ? AppColors.primary : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(data.currentPrice.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildMarketRow(MarketData stock, NumberFormat format) {
    final isUp = stock.changePercentage >= 0;
    final color = isUp ? AppColors.primary : Colors.redAccent;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssetDetailView(assetId: stock.symbol))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03))),
        ),
        child: Row(
          children: [
            // Symbol & Name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(stock.name, style: const TextStyle(color: Colors.white24, fontSize: 11), overflow: TextOverflow.ellipsis),
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
                  Text(format.format(stock.currentPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
