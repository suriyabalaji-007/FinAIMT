import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/data/repositories/mock_repository.dart';

class MarketNotifier extends Notifier<Map<String, MarketData>> {
  Timer? _timer;
  final Random _random = Random();

  @override
  Map<String, MarketData> build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    final initialState = _createInitialData();
    _startSimulatedStream();
    return initialState;
  }

  Map<String, MarketData> _createInitialData() {
    final stocks = {
      'RELIANCE': ['Reliance Industries', 2950.0],
      'TCS': ['Tata Consultancy Services', 4120.0],
      'HDFCBANK': ['HDFC Bank', 1450.0],
      'INFY': ['Infosys', 1620.0],
      'ICICIBANK': ['ICICI Bank', 1080.0],
      'BHARTIARTL': ['Bharti Airtel', 1210.0],
      'SBIN': ['State Bank of India', 760.0],
      'HINDUNILVR': ['Hindustan Unilever', 2340.0],
      'ITC': ['ITC Limited', 420.0],
      'KOTAKBANK': ['Kotak Mahindra Bank', 1710.0],
    };

    final map = <String, MarketData>{
      'NIFTY50': MarketData(
        symbol: 'NIFTY50',
        name: 'NIFTY 50',
        currentPrice: 22400.50,
        priceChange: 45.20,
        changePercentage: 0.20,
        lastUpdated: DateTime.now(),
        history: List.generate(30, (i) => 22350.0 + _random.nextDouble() * 100),
      ),
      'SENSEX': MarketData(
        symbol: 'SENSEX',
        name: 'SENSEX',
        currentPrice: 73800.00,
        priceChange: 120.50,
        changePercentage: 0.16,
        lastUpdated: DateTime.now(),
        history: List.generate(30, (i) => 73700.0 + _random.nextDouble() * 200),
      ),
    };

    stocks.forEach((sym, details) {
      final name = details[0] as String;
      final price = details[1] as double;
      map[sym] = MarketData(
        symbol: sym,
        name: name,
        currentPrice: price,
        priceChange: (price * (_random.nextDouble() * 0.02 - 0.01)),
        changePercentage: (_random.nextDouble() * 2 - 1),
        lastUpdated: DateTime.now(),
        history: List.generate(30, (i) => (price * 0.99) + _random.nextDouble() * (price * 0.02)),
      );
    });

    // Add ETFs
    MockRepository.getETFs().forEach((etf) {
      map[etf.symbol] = etf;
    });

    // Add Post Office Schemes
    MockRepository.getPostOfficeSchemes().forEach((scheme) {
      map[scheme.id] = MarketData(
        symbol: scheme.id,
        name: scheme.name,
        currentPrice: scheme.minInvestment, // Initial view
        priceChange: 0,
        changePercentage: 0,
        lastUpdated: DateTime.now(),
        history: [scheme.minInvestment],
      );
    });

    return map;
  }

  void _startSimulatedStream() {
    // 1-second ticks for high frequency "Kite" feel
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final updatedState = Map<String, MarketData>.from(state);
      
      updatedState.forEach((key, data) {
        // More aggressive simulation for stocks (±0.1% per second)
        final volatility = key.contains('NIFTY') || key.contains('SENSEX') ? 0.0005 : 0.0015;
        final movementPercent = (_random.nextDouble() * (volatility * 2)) - volatility;
        final newPrice = data.currentPrice * (1 + movementPercent);
        
        final priceChange = data.priceChange + (newPrice - data.currentPrice);
        final changePercentage = (priceChange / (newPrice - priceChange)) * 100;
        
        final newHistory = List<double>.from(data.history);
        newHistory.add(newPrice);
        if (newHistory.length > 30) newHistory.removeAt(0);
        
        updatedState[key] = data.copyWith(
          currentPrice: newPrice,
          priceChange: priceChange,
          changePercentage: double.parse(changePercentage.toStringAsFixed(2)),
          lastUpdated: DateTime.now(),
          history: newHistory,
        );
      });
      
      state = updatedState;
    });
  }
}

final marketDataProvider = NotifierProvider<MarketNotifier, Map<String, MarketData>>(MarketNotifier.new);
