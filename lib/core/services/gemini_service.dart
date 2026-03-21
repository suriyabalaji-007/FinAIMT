import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/providers/loans_provider.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/providers/metrics_provider.dart';
import 'package:fin_aimt/data/providers/chat_provider.dart';
import 'package:intl/intl.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiKey = ref.watch(geminiApiKeyProvider);
  return GeminiService(ref, apiKey);
});

class GeminiService {
  final Ref _ref;
  final String apiKey;
  late final GenerativeModel _model;
  ChatSession? _chat;

  GeminiService(this._ref, this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_buildSystemPrompt()),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.9,
        maxOutputTokens: 500,
      ),
    );
  }

  String _buildSystemPrompt() {
    return '''
You are FinBot, an expert AI financial advisor for Indian users in the FinAIMT app.

YOUR PERSONALITY:
- Friendly, professional, and concise
- Use Indian financial context (₹, Indian banks, NSE/BSE, Indian tax slabs)
- Give specific, actionable advice backed by numbers
- Use emojis sparingly for readability
- Keep responses under 150 words
- Never say you are an AI language model — you ARE FinBot

YOUR CAPABILITIES:
- Analyze spending patterns and suggest savings
- Recommend investment strategies based on risk profile
- Calculate EMI affordability and loan prepayment benefits
- Explain Indian tax rules (80C, 80D, HRA, capital gains)
- Compare investment options (FDs, MFs, Stocks, Gold, PPF)
- Suggest portfolio rebalancing

RESPONSE FORMAT:
- Use bullet points for multiple recommendations
- Include specific numbers when possible
- End with a clear call-to-action or follow-up question
''';
  }

  String _buildFinancialContext() {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    try {
      final finance = _ref.read(financeDataProvider);
      final loans = _ref.read(loansProvider);
      final investments = _ref.read(dynamicInvestmentsProvider);
      final metrics = _ref.read(metricsProvider);

      final totalBalance = finance.totalBalance;
      final totalEmi = loans.fold<double>(0, (sum, l) => sum + l.emi);
      final totalInvested = investments.fold<double>(0, (sum, i) => sum + i.investedAmount);
      final totalCurrent = investments.fold<double>(0, (sum, i) => sum + i.currentAmount);
      final totalProfit = totalCurrent - totalInvested;

      return '''
[USER'S LIVE FINANCIAL DATA]
Bank Balance: ${fmt.format(totalBalance)}
Monthly Income: ${fmt.format(metrics.income)}
Monthly Expenses: ${fmt.format(metrics.expense)}
Savings Rate: ${metrics.income > 0 ? ((metrics.income - metrics.expense) / metrics.income * 100).toStringAsFixed(1) : 'N/A'}%

Active Loans: ${loans.length}
Total Monthly EMI: ${fmt.format(totalEmi)}
EMI-to-Income Ratio: ${metrics.income > 0 ? (totalEmi / metrics.income * 100).toStringAsFixed(1) : 'N/A'}%

Investment Portfolio: ${fmt.format(totalCurrent)}
Total Invested: ${fmt.format(totalInvested)}
Net P&L: ${fmt.format(totalProfit)} (${totalInvested > 0 ? (totalProfit / totalInvested * 100).toStringAsFixed(1) : '0'}%)
Holdings: ${investments.map((i) => '${i.name}: ${fmt.format(i.currentAmount)}').join(', ')}

Loan Details: ${loans.map((l) => '${l.title} (${l.bank}): EMI ${fmt.format(l.emi)}, Remaining ${fmt.format(l.remainingAmount)}, Rate ${l.interestRate}%').join(' | ')}

Credit Cards: ${finance.creditCards.map((c) => '${c.cardName}: ${c.utilization.toStringAsFixed(0)}% used').join(', ')}

Top Expense Categories: ${metrics.expenseCategories.entries.map((e) => '${e.key}: ${fmt.format(e.value)}').join(', ')}
''';
    } catch (e) {
      return '[Financial data currently loading...]';
    }
  }

  Future<String> sendMessage(String userMessage) async {
    try {
      // Rebuild chat with fresh context each time
      _chat = _model.startChat();

      // Send context + user message
      final contextualMessage = '${_buildFinancialContext()}\n\nUser: $userMessage';
      
      if (apiKey.trim().isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return '⚠️ Please configure your Gemini API key in the settings (gear icon) first.';
      }

      final response = await _chat!.sendMessage(Content.text(contextualMessage));

      return response.text ?? 'I couldn\'t process that. Please try again.';
    } catch (e) {
      if (e.toString().contains('API key')) {
        return '⚠️ API key issue. Please check your Gemini API key configuration.';
      }
      return '⚠️ Connection issue. Please check your internet and try again.';
    }
  }
}
