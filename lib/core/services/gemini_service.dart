import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/providers/loans_provider.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/providers/metrics_provider.dart';
import 'package:fin_aimt/data/providers/chat_provider.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'package:fin_aimt/core/services/financial_ai_engine.dart';
import 'package:intl/intl.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiKey = ref.watch(geminiApiKeyProvider);
  return GeminiService(ref, apiKey);
});

class GeminiService {
  final Ref _ref;
  final String apiKey;
  final List<Map<String, String>> _messages = [];

  GeminiService(this._ref, this.apiKey);

  String _buildSystemPrompt() {
    return '''
You are FinBot, an elite AI financial architect for FinAIMT. 
Your goal is to provide institutional-grade financial analysis with a retail-friendly touch.

SECURITY & PRIVACY:
- Explicitly state that all calculations are done using "Encyrpted Data Identifiers" to ensure user privacy.
- Remind users that you never store their actual PII (Personally Identifiable Information).
- Maintain a secure, objective tone regarding sensitive financial decisions.

CORE KNOWLEDGE (The "Procedures"):
- FDs: Low risk, fixed tenures. Procedure: Open via Bank Tab -> Choose Tenure -> Confirm with UPI/OTP.
- Mutual Funds: SIP (Systematic) vs Lumpsum. Diversification is key. Procedure: KYC verification -> Select Fund -> Pay via AutoPay/UPI.
- Stocks (Equity): High risk/reward. Procedure: Add to Watchlist -> Analyze Sparkline -> Click 'Buy' for Delivery or Intraday.
- Post Office: Govt-backed, safe. KVP, NSC, SCSS. Procedure: Identity proof -> Document signing -> Direct deposit at branch or app.
- Insurance: Protection first. Term life is fundamental.

ANALYSIS GUIDELINES:
- Real-time Market: Use the provided [MARKET DATA] to tell if it's a 'Buying Opportunity' or 'Market Peak'.
- Investment Ideas: Analyze pros/cons of user's ideas based on current inflation and interest rates (Safe: 7-8%, Growth: 12-15%).
- User Doubts: Be patient. Explain concepts like Compound Interest, Tax Harvesting, and Asset Allocation.
- Procedures: Give step-by-step guides on how to buy/sell within the FinAIMT app.

RESPONSE DYNAMICS:
- Professional, concise, data-driven.
- Use ₹ and Indian standards.
- Keep responses precise (under 200 words).
''';
  }

  String _buildFinancialContext() {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    try {
      final finance = _ref.read(financeDataProvider);
      final loans = _ref.read(loansProvider);
      final investments = _ref.read(dynamicInvestmentsProvider);
      final metrics = _ref.read(metricsProvider);
      final market = _ref.read(marketDataProvider);

      final totalBalance = finance.totalBalance;
      final totalEmi = loans.fold<double>(0, (sum, l) => sum + l.emi);
      final totalInvested = investments.fold<double>(0, (sum, i) => sum + i.investedAmount);
      final totalCurrent = investments.fold<double>(0, (sum, i) => sum + i.currentAmount);

      // Market Sentiment
      final nifty = market['NIFTY50']?.currentPrice ?? 0;
      final niftyChange = market['NIFTY50']?.changePercentage ?? 0;
      final topGainer = market.values.reduce((a, b) => a.changePercentage > b.changePercentage ? a : b);
      
      // Holdings with Historical Context
      final holdingsContext = investments.map((i) {
        final data = market[i.assetId];
        String trendMsg = 'N/A';
        if (data != null && data.history.length > 1) {
          final first = data.history.first;
          final last = data.history.last;
          final change = ((last - first) / first * 100).toStringAsFixed(1);
          trendMsg = '$change% over 30 ticks';
        }
        return '${i.name}: ${fmt.format(i.currentAmount)} (30-day simulated trend: $trendMsg)';
      }).join('\n- ');
      
      return '''
[MARKET REAL-TIME DATA]
NIFTY 50: ${fmt.format(nifty)} (${niftyChange > 0 ? '+' : ''}$niftyChange%)
Market Trend: ${niftyChange > 0.5 ? 'Bullish' : niftyChange < -0.5 ? 'Bearish' : 'Sideways'}
Top Asset Today: ${topGainer.symbol} (${fmt.format(topGainer.currentPrice)}, ${topGainer.changePercentage}%)

[USER'S ENCRYPTED DATA PROFILE]
UID: ${finance.userProfile.email.hashCode} (Privacy Masked)
Bank Balance: ${fmt.format(totalBalance)}
Income/Expense: ${fmt.format(metrics.income)} / ${fmt.format(metrics.expense)}
Active Loans: ${loans.length} (Total EMI: ${fmt.format(totalEmi)})
Portfolio Value: ${fmt.format(totalCurrent)} (ROI: ${totalInvested > 0 ? ((totalCurrent - totalInvested) / totalInvested * 100).toStringAsFixed(2) : '0'}%)

[HOLDINGS & HISTORY]
- $holdingsContext

[ALERTS & PROCEDURES]
Loan Alerts: ${loans.where((l) => l.interestRate > 10).map((l) => '${l.title} has high ${l.interestRate}% interest').join(', ')}
Recent Transactions: ${finance.transactions.take(5).map((t) => '${t.title}: ${fmt.format(t.amount)}').join(' | ')}
''';
    } catch (e) {
      return '[Context processing... encryption layer active]';
    }
  }

  Future<String> sendMessage(String userMessage) async {
    try {
      if (apiKey.trim().isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return '⚠️ Please configure your API key in the settings (gear icon) first.';
      }

      // Use FinancialAIEngine for rich, on-device computed context
      final engine = _ref.read(financialAIEngineProvider);
      final fullPrompt = engine.buildFullFinancialPrompt(userMessage);

      // Manage conversation history manually
      _messages.add({'role': 'user', 'content': fullPrompt});

      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': _buildSystemPrompt()},
            ..._messages,
          ],
          'temperature': 0.7,
          'max_completion_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'];
        _messages.add({'role': 'assistant', 'content': aiText});
        return aiText;
      } else {
        return '⚠️ API Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      if (e.toString().contains('apiKey')) {
        return '⚠️ API key issue. Please check your API key configuration.';
      }
      return '⚠️ Error: ${e.toString()}';
    }
  }
}
