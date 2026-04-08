import 'package:flutter/material.dart';
import 'package:fin_aimt/data/models/finance_models.dart';

class MockRepository {
  static UserProfile getUserProfile() {
    return UserProfile(
      name: 'Suriya K',
      email: 'suriya.k@example.com',
      phone: '+91 98765 43210',
      panNumber: 'ABCDE1234F',
      aadhaarNumber: '**** **** 1234',
      riskProfile: 'Moderate',
      isKycVerified: true,
    );
  }

  static List<BankAccount> getAccounts() {
    return [
      BankAccount(
        bankName: 'HDFC Bank',
        accountNumber: '**** 1234',
        balance: 145000.50,
        logoUrl: 'https://placeholder.com/hdfc',
      ),
      BankAccount(
        bankName: 'ICICI Bank',
        accountNumber: '**** 5678',
        balance: 62000.25,
        logoUrl: 'https://placeholder.com/icici',
      ),
    ];
  }

  static List<CreditCard> getCreditCards() {
    return [
      CreditCard(
        cardName: 'HDFC Regalia',
        cardNumber: '**** 4321',
        balance: 24500.00,
        limit: 500000.00,
        minPayment: 1200.00,
        dueDate: DateTime.now().add(const Duration(days: 12)),
        type: 'Visa',
      ),
      CreditCard(
        cardName: 'SBI SimplyClick',
        cardNumber: '**** 8765',
        balance: 12000.00,
        limit: 100000.00,
        minPayment: 500.00,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        type: 'Mastercard',
      ),
    ];
  }

  static List<Loan> getLoans() {
    return [
      Loan(
        id: 'L1',
        title: 'Home Loan',
        bank: 'HDFC Bank',
        totalAmount: 4500000,
        remainingAmount: 3850000,
        emi: 32500,
        interestRate: 8.5,
        nextDueDate: DateTime.now().add(const Duration(days: 15)),
        type: 'Home',
      ),
      Loan(
        id: 'L2',
        title: 'Education Loan',
        bank: 'SBI',
        totalAmount: 1200000,
        remainingAmount: 450000,
        emi: 12000,
        interestRate: 10.2,
        nextDueDate: DateTime.now().add(const Duration(days: 20)),
        type: 'Education',
      ),
    ];
  }

  static List<Transaction> getRecentTransactions() {
    return [
      Transaction(
        id: '1',
        title: 'Swiggy',
        subtitle: 'Food Delivery',
        amount: 450.00,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: TransactionType.debit,
        icon: Icons.fastfood,
        category: 'Food',
      ),
      Transaction(
        id: '2',
        title: 'Salary Deposit',
        subtitle: 'Tech Corp India',
        amount: 120000.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.credit,
        icon: Icons.work,
        category: 'Salary',
      ),
      Transaction(
        id: '3',
        title: 'Netflix',
        subtitle: 'Subscription',
        amount: 499.00,
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: TransactionType.debit,
        icon: Icons.subscriptions,
        category: 'Entertainment',
      ),
      Transaction(
        id: '4',
        title: 'Electricity Bill',
        subtitle: 'BESCOM',
        amount: 3200.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: TransactionType.debit,
        icon: Icons.electrical_services,
        category: 'Bills',
      ),
    ];
  }

  static List<Investment> getInvestments() {
    return [
      Investment(
        assetId: 'RELIANCE',
        name: 'Reliance Industries',
        investedAmount: 25000,
        currentAmount: 28500,
        changePercentage: 14.0,
        category: 'Stocks',
        history: [25000, 25500, 24800, 26000, 27500, 28500],
        quantity: 10,
        averagePrice: 2500,
      ),
      Investment(
        assetId: 'HDFC_FUND',
        name: 'HDFC Mid-Cap Fund',
        investedAmount: 50000,
        currentAmount: 54200,
        changePercentage: 8.4,
        category: 'Mutual Funds',
        history: [50000, 50500, 51000, 52000, 53000, 54200],
        quantity: 100,
        averagePrice: 500,
      ),
      Investment(
        assetId: 'PPF',
        name: 'Public Provident Fund (PPF)',
        investedAmount: 150000,
        currentAmount: 162000,
        changePercentage: 7.1,
        category: 'Post Office Schemes',
        history: [150000, 155000, 162000],
        quantity: 1,
        averagePrice: 150000,
      ),
      Investment(
        assetId: 'GOLD',
        name: 'Digital Gold',
        investedAmount: 10000,
        currentAmount: 11500,
        changePercentage: 15.0,
        category: 'Gold',
        history: [10000, 11000, 11500],
        quantity: 10,
        averagePrice: 1000,
      ),
      Investment(
        assetId: 'LIC',
        name: 'LIC Term Insurance',
        investedAmount: 15000,
        currentAmount: 15000,
        changePercentage: 0.0,
        category: 'Insurance',
        history: [15000, 15000],
        quantity: 1,
        averagePrice: 15000,
      ),
      Investment(
        assetId: 'STAR_HEALTH',
        name: 'Star Health Insurance',
        investedAmount: 12000,
        currentAmount: 12000,
        changePercentage: 0.0,
        category: 'Insurance',
        history: [12000, 12000],
        quantity: 1,
        averagePrice: 12000,
      ),
      Investment(
        assetId: 'NIFTYBEES',
        name: 'Nippon India Nifty BEES',
        investedAmount: 5000,
        currentAmount: 5200,
        changePercentage: 4.0,
        category: 'ETFs',
        history: [4800, 5000, 5200],
        quantity: 20,
        averagePrice: 250,
      ),
      Investment(
        assetId: 'NSC',
        name: 'National Savings Certificate',
        investedAmount: 10000,
        currentAmount: 10000,
        changePercentage: 0.0,
        category: 'Post Office Schemes',
        history: [10000],
        quantity: 1,
        averagePrice: 10000,
      ),
    ];
  }

  static List<AIInsight> getInsights() {
    return [
      AIInsight(
        title: 'High Credit Utilization',
        message: 'Your HDFC card usage is at 45%. Keep it below 30% to improve your CIBIL score.',
        type: InsightType.warning,
        timestamp: DateTime.now(),
      ),
      AIInsight(
        title: 'Tax Saving Opportunity',
        message: 'You can save ₹15,000 more under Section 80C by investing in ELSS funds.',
        type: InsightType.opportunity,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AIInsight(
        title: 'EMI Prepayment Tip',
        message: 'Paying an extra ₹5k monthly on Home Loan can save ₹4.2L in interest.',
        type: InsightType.tip,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  static TaxSummary getTaxSummary() {
    return TaxSummary(
      totalIncome: 1440000.00,
      taxableIncome: 1150000.00,
      deductions80C: 150000.00,
      estimatedTax: 85200.00,
      taxYear: '2024-25',
    );
  }

  static List<MarketData> getETFs() {
    return [
      MarketData(
        symbol: 'NIFTYBEES',
        name: 'Nippon India Nifty BEES',
        category: 'ETFs',
        currentPrice: 245.50,
        priceChange: 1.2,
        changePercentage: 0.49,
        lastUpdated: DateTime.now(),
        history: [240, 242, 245.5],
      ),
      MarketData(
        symbol: 'GOLDBEES',
        name: 'Nippon India Gold BEES',
        category: 'ETFs',
        currentPrice: 58.20,
        priceChange: -0.3,
        changePercentage: -0.51,
        lastUpdated: DateTime.now(),
        history: [59, 58.5, 58.2],
      ),
      MarketData(
        symbol: 'JUNIORBEES',
        name: 'Nippon India Junior BEES',
        category: 'ETFs',
        currentPrice: 560.00,
        priceChange: 5.5,
        changePercentage: 0.99,
        lastUpdated: DateTime.now(),
        history: [550, 555, 560],
      ),
      MarketData(
        symbol: 'NIFTY_ETF',
        name: 'Nifty 50 ETF',
        category: 'ETFs',
        currentPrice: 245.50,
        priceChange: 1.2,
        changePercentage: 0.49,
        lastUpdated: DateTime.now(),
        history: [240, 242, 245.5],
      ),
    ];
  }

  static List<PostOfficeScheme> getPostOfficeSchemes() {
    return [
      PostOfficeScheme(
        id: 'NSC',
        name: 'National Savings Certificate',
        interestRate: 7.7,
        tenureYears: 5,
        type: 'NSC',
        minInvestment: 1000,
      ),
      PostOfficeScheme(
        id: 'KVP',
        name: 'Kisan Vikas Patra',
        interestRate: 7.5,
        tenureYears: 9, // 115 months
        type: 'KVP',
        minInvestment: 1000,
      ),
      PostOfficeScheme(
        id: 'PO_MIS',
        name: 'Monthly Income Scheme',
        interestRate: 7.4,
        tenureYears: 5,
        type: 'MIS',
        minInvestment: 1000,
      ),
      PostOfficeScheme(
        id: 'SCSS',
        name: 'Senior Citizen Savings Scheme',
        interestRate: 8.2,
        tenureYears: 5,
        type: 'SCSS',
        minInvestment: 1000,
      ),
      PostOfficeScheme(
        id: 'PPF',
        name: 'Public Provident Fund',
        interestRate: 7.1,
        tenureYears: 15,
        type: 'PPF',
        minInvestment: 500,
      ),
      PostOfficeScheme(
        id: 'SSY',
        name: 'Sukanya Samriddhi Yojana',
        interestRate: 8.2,
        tenureYears: 21,
        type: 'SSY',
        minInvestment: 250,
      ),
      PostOfficeScheme(
        id: 'PO_RD',
        name: '5-Year Recurring Deposit',
        interestRate: 6.7,
        tenureYears: 5,
        type: 'RD',
        minInvestment: 100,
      ),
      PostOfficeScheme(
        id: 'PO_TD_5Y',
        name: '5-Year Time Deposit',
        interestRate: 7.5,
        tenureYears: 5,
        type: 'TD',
        minInvestment: 1000,
      ),
      PostOfficeScheme(
        id: 'MSSC',
        name: 'Mahila Samman Savings Certificate',
        interestRate: 7.5,
        tenureYears: 2,
        type: 'MSSC',
        minInvestment: 1000,
      ),
    ];
  }

  static List<InsuranceProduct> getInsuranceProducts() {
    return [
      InsuranceProduct(
        id: 'LIC_JEEVAN_LABH',
        provider: 'Life Insurance Corporation (LIC)',
        planName: 'Jeevan Labh (836)',
        type: 'Endowment',
        sumInsured: 2000000,
        annualPremium: 85000,
        logoUrl: 'https://placeholder.com/lic',
        benefits: ['High Bonus Rates', 'Limited Premium Payment', 'Tax Saving U/S 80C'],
      ),
      InsuranceProduct(
        id: 'LIC_JEEVAN_ANAND',
        provider: 'Life Insurance Corporation (LIC)',
        planName: 'New Jeevan Anand (815)',
        type: 'Whole Life',
        sumInsured: 1000000,
        annualPremium: 45000,
        logoUrl: 'https://placeholder.com/lic',
        benefits: ['Lifetime Protection', 'Double Tax Benefit', 'Maturity + Final Bonus'],
      ),
      InsuranceProduct(
        id: 'HDFC_ERGO_HEALTH',
        provider: 'HDFC ERGO',
        planName: 'Optima Restore',
        type: 'Health',
        sumInsured: 500000,
        annualPremium: 12500,
        logoUrl: 'https://placeholder.com/hdfc_ergo',
        benefits: ['Cashless Hospitalization', 'Restore Benefit', 'No Claim Bonus'],
      ),
      InsuranceProduct(
        id: 'ICICI_PRU_TERM',
        provider: 'ICICI Prudential',
        planName: 'iProtect Smart',
        type: 'Term',
        sumInsured: 10000000,
        annualPremium: 15600,
        logoUrl: 'https://placeholder.com/icici_pru',
        benefits: ['Terminal Illness Cover', 'Accidental Death Benefit', 'Tax Benefits'],
      ),
      InsuranceProduct(
        id: 'STAR_HEALTH',
        provider: 'Star Health',
        planName: 'Family Health Optima',
        type: 'Health',
        sumInsured: 1000000,
        annualPremium: 18450,
        logoUrl: 'https://placeholder.com/star_health',
        benefits: ['No Claim Bonus', 'Free Health Checkup', 'Cover for 400+ Day Care'],
      ),
      InsuranceProduct(
        id: 'NIACL_HEALTH',
        provider: 'New India Assurance',
        planName: 'Arogya Sanjeevani',
        type: 'Health',
        sumInsured: 500000,
        annualPremium: 8200,
        logoUrl: 'https://placeholder.com/niacl',
        benefits: ['Low Premium', 'Govt Mandated Coverage', 'Standard Policy'],
      ),
    ];
  }

  static List<MarketData> getMutualFunds() {
    return [
      MarketData(
        symbol: 'HDFC_MIDCAP',
        name: 'HDFC Mid-Cap Opportunities Fund',
        category: 'Mutual Funds',
        currentPrice: 156.40,
        priceChange: 0.85,
        changePercentage: 0.55,
        lastUpdated: DateTime.now(),
        history: [150, 153.2, 156.4],
      ),
      MarketData(
        symbol: 'ICICI_BLUECHIP',
        name: 'ICICI Prudential Bluechip Fund',
        category: 'Mutual Funds',
        currentPrice: 89.20,
        priceChange: -0.15,
        changePercentage: -0.17,
        lastUpdated: DateTime.now(),
        history: [90, 89.5, 89.2],
      ),
      MarketData(
        symbol: 'SBI_SMALLCAP',
        name: 'SBI Small Cap Fund',
        category: 'Mutual Funds',
        currentPrice: 142.10,
        priceChange: 2.1,
        changePercentage: 1.5,
        lastUpdated: DateTime.now(),
        history: [135, 138.5, 142.1],
      ),
      MarketData(
        symbol: 'AXIS_ELSS',
        name: 'Axis Long Term Equity Fund (ELSS)',
        category: 'Mutual Funds',
        currentPrice: 78.45,
        priceChange: 0.4,
        changePercentage: 0.51,
        lastUpdated: DateTime.now(),
        history: [75, 77.2, 78.45],
      ),
      MarketData(
        symbol: 'NIPPON_INDIA_GROWTH',
        name: 'Nippon India Growth Fund',
        category: 'Mutual Funds',
        currentPrice: 2450.75,
        priceChange: 12.50,
        changePercentage: 0.51,
        lastUpdated: DateTime.now(),
        history: [2400, 2430, 2450.75],
      ),
    ];
  }
}
