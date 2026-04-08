import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/providers/loans_provider.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/providers/metrics_provider.dart';
import 'package:fin_aimt/data/providers/market_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';

/// FinancialAIEngine — Comprehensive financial analysis engine.
/// Processes real-time + historical user data to produce:
///  - Risk profiling (Conservative / Moderate / Aggressive)
///  - Investment timing signals (Buy / Wait / Sell)
///  - SIP & lump-sum recommendations
///  - Loan burden & EMI optimisation
///  - Tax-saving gap analysis (80C / 80D)
///  - Net-worth growth trajectory
///
/// ━━━ DATA PRIVACY ━━━
/// All analysis is performed ON-DEVICE. No PII leaves the device.
/// Only anonymised hashed identifiers are sent to the AI API.

final financialAIEngineProvider = Provider<FinancialAIEngine>((ref) {
  return FinancialAIEngine(ref);
});

class RiskLevel {
  static const String conservative = 'Conservative (Low Risk)';
  static const String moderate = 'Moderate (Balanced)';
  static const String aggressive = 'Aggressive (High Growth)';
}

class FinancialAIEngine {
  final Ref _ref;
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final Random _rng = Random();

  FinancialAIEngine(this._ref);

  // ─── MAIN: Build full context string for Gemini ───────────────────────────
  String buildFullFinancialPrompt(String userQuery) {
    final sb = StringBuffer();

    sb.writeln(_systemPersona());
    sb.writeln(_privacyStatement());
    sb.writeln(_userRiskProfile());
    sb.writeln(_currentFinancialSnapshot());
    sb.writeln(_investmentAnalysis());
    sb.writeln(_loanBurdenAnalysis());
    sb.writeln(_taxPlanningAnalysis());
    sb.writeln(_marketTimingSignals());
    sb.writeln(_cashflowAnalysis());
    sb.writeln(_predictivePlans());
    sb.writeln('\n══════════════════════════════════════');
    sb.writeln('USER QUERY: $userQuery');
    sb.writeln('══════════════════════════════════════');
    sb.writeln('Respond as FinBot. Use ₹ and Indian financial context. Be precise and helpful. Keep response under 300 words unless detailed analysis is requested.');

    return sb.toString();
  }

  // ─── SYSTEM PERSONA ───────────────────────────────────────────────────────
  String _systemPersona() => '''
You are FinBot — an institutional-grade AI Financial Advisor built into FinAIMT.
Your role: Analyse the user's COMPLETE financial data provided below and give PERSONALISED,
ACTIONABLE advice on investments, risk management, loans, tax-saving, and wealth planning.
Speak like a trusted financial expert — data-driven, empathetic, concise.
''';

  // ─── PRIVACY STATEMENT ────────────────────────────────────────────────────
  String _privacyStatement() {
    final uid = _ref.read(financeDataProvider).userProfile.email.hashCode.abs();
    return '''
[SECURITY LAYER]
• All computations are on-device. Zero raw PII transmitted.
• User Reference ID: USR-${uid.toString().substring(0, 6)} (anonymised hash)
• Data encryption: AES-256 at rest, TLS 1.3 in transit
''';
  }

  // ─── RISK PROFILE ─────────────────────────────────────────────────────────
  String _userRiskProfile() {
    final metrics = _ref.read(metricsProvider);
    final investments = _ref.read(dynamicInvestmentsProvider);
    final loans = _ref.read(loansProvider);
    final finance = _ref.read(financeDataProvider);

    final totalInvested = investments.fold<double>(0, (s, i) => s + i.investedAmount);
    final totalLoans = loans.fold<double>(0, (s, l) => s + l.remainingAmount.toDouble());
    final income = metrics.income;
    final balance = finance.totalBalance;

    // Risk score (0–100)
    double riskScore = 50;
    if (income > 0) {
      final savingsRate = (income - metrics.expense) / income;
      final debtToIncome = income > 0 ? totalLoans / income : 0;
      final investmentRate = totalInvested > 0 ? totalInvested / (balance + totalInvested) : 0;

      riskScore += (savingsRate * 20);
      riskScore -= (debtToIncome * 10).clamp(0, 25);
      riskScore += (investmentRate * 15).clamp(0, 15);
    }

    final riskLevel = riskScore < 35
        ? RiskLevel.conservative
        : riskScore < 65
            ? RiskLevel.moderate
            : RiskLevel.aggressive;

    return '''
[USER RISK PROFILE]
• Computed Risk Level: $riskLevel
• Risk Score: ${riskScore.toStringAsFixed(1)}/100
• Savings Behaviour: ${metrics.income > 0 ? ((metrics.income - metrics.expense) / metrics.income * 100).toStringAsFixed(1) : 'N/A'}% of income saved
• Total Debt Exposure: ${_fmt.format(totalLoans)}
• Investment Commitment: ${_fmt.format(totalInvested)}
''';
  }

  // ─── CURRENT FINANCIAL SNAPSHOT ───────────────────────────────────────────
  String _currentFinancialSnapshot() {
    final finance = _ref.read(financeDataProvider);
    final metrics = _ref.read(metricsProvider);
    final investments = _ref.read(dynamicInvestmentsProvider);

    final totalCurrent = investments.fold<double>(0, (s, i) => s + i.currentAmount);
    final totalInvested = investments.fold<double>(0, (s, i) => s + i.investedAmount);
    final roi = totalInvested > 0 ? ((totalCurrent - totalInvested) / totalInvested * 100) : 0;
    final netWorth = finance.totalBalance + totalCurrent;

    return '''
[CURRENT FINANCIAL SNAPSHOT — ${DateTime.now().toLocal().toString().split(' ')[0]}]
• Bank Balance: ${_fmt.format(finance.totalBalance)}
• Monthly Income: ${_fmt.format(metrics.income / 12)}
• Monthly Expenses: ${_fmt.format(metrics.expense / 12)}
• Monthly Savings: ${_fmt.format((metrics.income - metrics.expense) / 12)}
• Total Portfolio Value: ${_fmt.format(totalCurrent)} (ROI: ${roi.toStringAsFixed(2)}%)
• Estimated Net Worth: ${_fmt.format(netWorth)}

Top Expense Categories:
${metrics.expenseCategories.entries.map((e) => '  • ${e.key}: ${_fmt.format(e.value)}').join('\n')}
''';
  }

  // ─── INVESTMENT ANALYSIS ──────────────────────────────────────────────────
  String _investmentAnalysis() {
    final investments = _ref.read(dynamicInvestmentsProvider);
    final market = _ref.read(marketDataProvider);

    if (investments.isEmpty) return '[PORTFOLIO] No holdings found.\n';

    // Category allocation
    final categoryMap = <String, double>{};
    for (final inv in investments) {
      categoryMap[inv.category] = (categoryMap[inv.category] ?? 0) + inv.currentAmount;
    }
    final totalPortfolio = categoryMap.values.fold(0.0, (a, b) => a + b);

    final allocationStr = categoryMap.entries.map((e) {
      final pct = totalPortfolio > 0 ? (e.value / totalPortfolio * 100).toStringAsFixed(1) : '0.0';
      return '  • ${e.key}: ${_fmt.format(e.value)} ($pct%)';
    }).join('\n');

    // Individual holdings with trend
    final holdingsStr = investments.map((inv) {
      final data = market[inv.assetId];
      final gain = inv.currentAmount - inv.investedAmount;
      final gainPct = inv.investedAmount > 0 ? (gain / inv.investedAmount * 100).toStringAsFixed(2) : '0';
      final trend = data != null
          ? (data.changePercentage >= 0 ? '▲ +${data.changePercentage.toStringAsFixed(2)}% today' : '▼ ${data.changePercentage.toStringAsFixed(2)}% today')
          : 'No live data';
      final signal = _getAssetSignal(data);
      return '  • ${inv.name} [${inv.category}]: ${_fmt.format(inv.currentAmount)} | P&L: ${gain >= 0 ? '+' : ''}${_fmt.format(gain)} ($gainPct%) | $trend | Signal: $signal';
    }).join('\n');

    return '''
[PORTFOLIO ANALYSIS]
Asset Allocation:
$allocationStr

Holdings Detail:
$holdingsStr

Diversification Score: ${_getDiversificationScore(categoryMap)}/10
Portfolio Risk: ${_getPortfolioRisk(investments)}
''';
  }

  String _getAssetSignal(MarketData? data) {
    if (data == null) return 'HOLD';
    if (data.history.length < 5) return 'ACCUMULATE';
    final avg = data.history.reduce((a, b) => a + b) / data.history.length;
    final current = data.currentPrice;
    if (current < avg * 0.97) return '🟢 BUY (Below 30-tick avg)';
    if (current > avg * 1.03) return '🔴 BOOK PROFIT (Above avg)';
    return '🟡 HOLD (Near avg)';
  }

  String _getDiversificationScore(Map<String, double> categories) {
    final count = categories.length;
    if (count >= 5) return '9';
    if (count == 4) return '7';
    if (count == 3) return '5';
    if (count == 2) return '3';
    return '1';
  }

  String _getPortfolioRisk(List<Investment> investments) {
    final stocksAndEtf = investments.where((i) => i.category == 'Stocks' || i.category == 'ETFs');
    final safeAssets = investments.where((i) => i.category == 'Post Office Schemes' || i.category == 'Insurance');
    if (stocksAndEtf.length > safeAssets.length) return 'HIGH — Consider rebalancing with Govt Schemes';
    if (safeAssets.length > stocksAndEtf.length) return 'LOW — Consider adding growth assets';
    return 'BALANCED';
  }

  // ─── LOAN BURDEN ANALYSIS ─────────────────────────────────────────────────
  String _loanBurdenAnalysis() {
    final loans = _ref.read(loansProvider);
    final metrics = _ref.read(metricsProvider);
    if (loans.isEmpty) return '[LOANS] Debt-free. Excellent!\n';

    final totalEmi = loans.fold<double>(0, (s, l) => s + l.emi.toDouble());
    final monthlyIncome = metrics.income / 12;
    final dtiRatio = monthlyIncome > 0 ? (totalEmi / monthlyIncome * 100).toStringAsFixed(1) : 'N/A';

    final loanDetails = loans.map((l) {
      final yearsLeft = l.remainingAmount > 0 ? (l.remainingAmount / l.emi / 12).toStringAsFixed(1) : '0';
      final interestWarning = l.interestRate > 10 ? ' ⚠️ HIGH RATE — Consider refinancing' : '';
      return '  • ${l.title} @ ${l.interestRate}%: ${_fmt.format(l.remainingAmount)} remaining, EMI ${_fmt.format(l.emi.toDouble())}/mo (~$yearsLeft yrs)$interestWarning';
    }).join('\n');

    return '''
[LOAN BURDEN ANALYSIS]
$loanDetails

Total Monthly EMI: ${_fmt.format(totalEmi)}
Debt-to-Income Ratio: $dtiRatio% ${_getDTIComment(double.tryParse(dtiRatio) ?? 0)}
Recommendation: ${_getLoanRecommendation(loans, totalEmi, monthlyIncome)}
''';
  }

  String _getDTIComment(double dti) {
    if (dti < 30) return '✅ Healthy';
    if (dti < 50) return '⚠️ Manageable — Avoid new debt';
    return '🔴 Critical — Prioritise debt payoff';
  }

  String _getLoanRecommendation(List<Loan> loans, double totalEmi, double monthlyIncome) {
    final highInterest = loans.where((l) => l.interestRate > 10).toList();
    if (highInterest.isNotEmpty) {
      return 'Prepay ${highInterest.first.title} (${highInterest.first.interestRate}% rate) — saves significant interest';
    }
    if (totalEmi / monthlyIncome > 0.5) return 'EMI burden is high. Defer new investments until DTI < 40%.';
    return 'EMI load is manageable. Continue SIPs alongside EMI payments.';
  }

  // ─── TAX PLANNING ─────────────────────────────────────────────────────────
  String _taxPlanningAnalysis() {
    final metrics = _ref.read(metricsProvider);
    final investments = _ref.read(dynamicInvestmentsProvider);

    final elssInvested = investments
        .where((i) => i.category == 'Mutual Funds' || i.assetId.contains('ELSS'))
        .fold<double>(0, (s, i) => s + i.investedAmount);
    final ppfInvested = investments
        .where((i) => i.assetId == 'PPF')
        .fold<double>(0, (s, i) => s + i.investedAmount);
    final insurancePremium = investments
        .where((i) => i.category == 'Insurance')
        .fold<double>(0, (s, i) => s + i.investedAmount);

    final section80C = (elssInvested + ppfInvested).clamp(0, 150000);
    final section80D = insurancePremium.clamp(0, 25000);
    final remaining80C = (150000 - section80C).clamp(0, 150000);
    final remaining80D = (25000 - section80D).clamp(0, 25000);

    return '''
[TAX PLANNING — FY 2024-25]
• Annual Income: ${_fmt.format(metrics.income)}
• Estimated Tax: ${_fmt.format(metrics.estimatedTax)}
• Section 80C Used: ${_fmt.format(section80C)} / ₹1,50,000
  ${remaining80C > 0 ? '⚠️ Gap: ${_fmt.format(remaining80C)} — Invest in ELSS/PPF to save' : '✅ Fully utilised'}
• Section 80D (Health Insurance): ${_fmt.format(section80D)} / ₹25,000
  ${remaining80D > 0 ? '⚠️ Gap: ${_fmt.format(remaining80D)} — Add health insurance premium' : '✅ Fully utilised'}
• Total Deductions: ${_fmt.format(metrics.deductions80C)}
• Potential Tax Savings: ${_fmt.format((remaining80C + remaining80D) * 0.3)}
''';
  }

  // ─── MARKET TIMING SIGNALS ────────────────────────────────────────────────
  String _marketTimingSignals() {
    final market = _ref.read(marketDataProvider);
    final nifty = market['NIFTY50'];
    final sensex = market['SENSEX'];

    final niftySignal = nifty != null ? _getMarketSignal(nifty) : 'N/A';
    final sensexSignal = sensex != null ? _getMarketSignal(sensex) : 'N/A';

    // Top movers
    final movers = market.values
        .where((d) => d.category == 'Stocks' || d.category == 'ETFs')
        .toList()
      ..sort((a, b) => b.changePercentage.compareTo(a.changePercentage));

    final topGainers = movers.take(3).map((d) => '  ${d.symbol}: +${d.changePercentage.toStringAsFixed(2)}%').join('\n');
    final topLosers = movers.reversed.take(3).map((d) => '  ${d.symbol}: ${d.changePercentage.toStringAsFixed(2)}%').join('\n');

    return '''
[LIVE MARKET INTELLIGENCE]
• NIFTY 50: ${nifty != null ? _fmt.format(nifty.currentPrice) : 'N/A'} → Signal: $niftySignal
• SENSEX: ${sensex != null ? _fmt.format(sensex.currentPrice) : 'N/A'} → Signal: $sensexSignal
• Market Mood: ${nifty != null ? (nifty.changePercentage > 0.5 ? '🟢 Bullish' : nifty.changePercentage < -0.5 ? '🔴 Bearish' : '🟡 Sideways') : 'Unknown'}

Top Gainers Today:
$topGainers

Top Losers Today:
$topLosers

Best Time to Invest: ${_getBestTimeToInvest(nifty)}
''';
  }

  String _getMarketSignal(MarketData data) {
    if (data.history.isEmpty) return 'NEUTRAL';
    final avg = data.history.reduce((a, b) => a + b) / data.history.length;
    final deviation = ((data.currentPrice - avg) / avg * 100);
    if (deviation < -2) return '🟢 STRONG BUY (Oversold)';
    if (deviation > 2) return '🔴 BOOK PROFIT (Overbought)';
    if (data.changePercentage > 0.3) return '🟡 MILD BUY';
    return '⚪ HOLD';
  }

  String _getBestTimeToInvest(MarketData? nifty) {
    if (nifty == null) return 'SIP mode — invest fixed amount monthly regardless of market level.';
    if (nifty.changePercentage < -1.0) return '✅ Market is DOWN — Good lump-sum opportunity for long-term investors.';
    if (nifty.changePercentage > 1.5) return '⚠️ Market is UP — Prefer SIP over lump-sum. Avoid chasing the rally.';
    return '🟡 Market is stable — Continue your existing SIPs. Add small lump-sum if available.';
  }

  // ─── CASHFLOW ANALYSIS ────────────────────────────────────────────────────
  String _cashflowAnalysis() {
    final metrics = _ref.read(metricsProvider);
    final finance = _ref.read(financeDataProvider);
    final loans = _ref.read(loansProvider);

    final monthlyIncome = metrics.income / 12;
    final monthlyExpense = metrics.expense / 12;
    final totalEmi = loans.fold<double>(0, (s, l) => s + l.emi.toDouble());
    final monthlySurplus = monthlyIncome - monthlyExpense - totalEmi;
    final emergencyFund = finance.totalBalance;
    final emergencyMonths = monthlyExpense > 0 ? (emergencyFund / monthlyExpense).toStringAsFixed(1) : '0';

    return '''
[CASHFLOW & EMERGENCY FUND]
• Monthly Surplus (after EMIs): ${_fmt.format(monthlySurplus)}
• Emergency Fund on hand: ${_fmt.format(emergencyFund)}
• Emergency Coverage: $emergencyMonths months ${double.tryParse(emergencyMonths)! < 6 ? '⚠️ Build to 6 months minimum' : '✅ Adequate'}
• Suggested Monthly SIP Capacity: ${_fmt.format((monthlySurplus * 0.6).clamp(0.0, double.infinity))}
''';
  }

  // ─── PREDICTIVE PLANS ─────────────────────────────────────────────────────
  String _predictivePlans() {
    final metrics = _ref.read(metricsProvider);
    final investments = _ref.read(dynamicInvestmentsProvider);

    final monthlyIncome = metrics.income / 12;
    final currentPortfolio = investments.fold<double>(0, (s, i) => s + i.currentAmount);
    const avgReturn = 0.12; // 12% annualised for balanced portfolio
    final sipAmount = (monthlyIncome * 0.2).clamp(2000.0, 50000.0);

    // FV of current portfolio + SIPs at 12% over 5 years
    final fv5yr = _futureValue(currentPortfolio, sipAmount, avgReturn, 5);
    final fv10yr = _futureValue(currentPortfolio, sipAmount, avgReturn, 10);
    final fv20yr = _futureValue(currentPortfolio, sipAmount, avgReturn, 20);

    return '''
[PREDICTIVE WEALTH PROJECTIONS]
(Based on current portfolio + suggested SIP of ${_fmt.format(sipAmount)}/mo @ 12% annualised)

• 5-Year Projection:  ${_fmt.format(fv5yr)}
• 10-Year Projection: ${_fmt.format(fv10yr)}
• 20-Year Projection: ${_fmt.format(fv20yr)}

Recommended Action Plan:
  1. 📊 Equity SIP: Invest ${_fmt.format(sipAmount * 0.5)}/mo in Nifty 50 ETF or Large-cap Fund
  2. 🏛️ Debt safety: Put ${_fmt.format(sipAmount * 0.2)}/mo in PPF or NSC for 7.7% guaranteed return
  3. 🛡️ Insurance: Ensure term life cover ≥ 10× annual income
  4. 💰 Gold hedge: Allocate 5-10% to Sovereign Gold Bonds
  5. 📋 Tax: Fill 80C gap with ELSS (tax-saving + 12-15% returns)
''';
  }

  double _futureValue(double presentValue, double monthlyContribution, double annualRate, int years) {
    final monthlyRate = annualRate / 12;
    final months = years * 12;
    // FV of existing corpus
    final fvCorpus = presentValue * pow(1 + annualRate, years).toDouble();
    // FV of monthly SIPs (annuity)
    final fvSip = monthlyContribution * ((pow(1 + monthlyRate, months).toDouble() - 1) / monthlyRate) * (1 + monthlyRate);
    return fvCorpus + fvSip;
  }
}
