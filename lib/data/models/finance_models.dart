import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final IconData icon;
  final String category;

  Transaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
    required this.icon,
    this.category = 'General',
  });
}

enum TransactionType { credit, debit }

class BankAccount {
  final String bankName;
  final String accountNumber;
  final double balance;
  final String logoUrl;
  final bool isUpiEnabled;

  BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.balance,
    required this.logoUrl,
    this.isUpiEnabled = true,
  });
}

class CreditCard {
  final String cardName;
  final String cardNumber;
  final double balance;
  final double limit;
  final double minPayment;
  final DateTime dueDate;
  final String type; // Visa, Mastercard, etc.

  CreditCard({
    required this.cardName,
    required this.cardNumber,
    required this.balance,
    required this.limit,
    required this.minPayment,
    required this.dueDate,
    required this.type,
  });

  double get utilization => (balance / limit) * 100;
}

class Loan {
  final String id;
  final String title;
  final String bank;
  final double totalAmount;
  final double remainingAmount;
  final double emi;
  final double interestRate;
  final DateTime nextDueDate;
  final String type; // Home, Personal, Education

  Loan({
    required this.id,
    required this.title,
    required this.bank,
    required this.totalAmount,
    required this.remainingAmount,
    required this.emi,
    required this.interestRate,
    required this.nextDueDate,
    required this.type,
  });

  double get progress => (totalAmount - remainingAmount) / (totalAmount > 0 ? totalAmount : 1);

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      title: json['title'],
      bank: json['bank'],
      totalAmount: (json['totalAmount'] ?? 0) / 100,
      remainingAmount: (json['remainingAmount'] ?? 0) / 100,
      emi: (json['emi'] ?? 0) / 100,
      interestRate: (json['interestRate'] ?? 0).toDouble(),
      nextDueDate: DateTime.parse(json['nextDueDate']),
      type: json['type'],
    );
  }
}

class Investment {
  final String? id;
  final String assetId;
  final String name;
  final double investedAmount;
  final double currentAmount;
  final double changePercentage;
  final String category;
  final List<double> history; // For sparklines/charts
  final double quantity;
  final double averagePrice;

  Investment({
    this.id,
    required this.assetId,
    required this.name,
    required this.investedAmount,
    required this.currentAmount,
    required this.changePercentage,
    required this.category,
    this.history = const [],
    this.quantity = 0,
    this.averagePrice = 0,
  });

  Investment copyWith({
    String? id,
    String? assetId,
    String? name,
    double? investedAmount,
    double? currentAmount,
    double? changePercentage,
    String? category,
    List<double>? history,
    double? quantity,
    double? averagePrice,
  }) {
    return Investment(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      name: name ?? this.name,
      investedAmount: investedAmount ?? this.investedAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      changePercentage: changePercentage ?? this.changePercentage,
      category: category ?? this.category,
      history: history ?? this.history,
      quantity: quantity ?? this.quantity,
      averagePrice: averagePrice ?? this.averagePrice,
    );
  }

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      assetId: json['assetId'],
      name: json['assetName'],
      investedAmount: (json['quantity'] ?? 0) * (json['averagePrice'] ?? 0) / 100,
      currentAmount: (json['quantity'] ?? 0) * (json['averagePrice'] ?? 0) / 100, // Will be updated by price service
      changePercentage: 0,
      category: json['category'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0) / 100,
    );
  }
}

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String panNumber;
  final String aadhaarNumber;
  final String riskProfile; // Conservative, Moderate, Aggressive
  final bool isKycVerified;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.panNumber,
    required this.aadhaarNumber,
    required this.riskProfile,
    this.isKycVerified = false,
  });
}

class AIInsight {
  final String title;
  final String message;
  final InsightType type;
  final DateTime timestamp;

  AIInsight({
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

enum InsightType { alert, tip, opportunity, warning }
class TaxSummary {
  final double totalIncome;
  final double taxableIncome;
  final double deductions80C;
  final double estimatedTax;
  final String taxYear;

  TaxSummary({
    required this.totalIncome,
    required this.taxableIncome,
    required this.deductions80C,
    required this.estimatedTax,
    required this.taxYear,
  });
}

class MarketData {
  final String symbol; // e.g., 'GOLD', 'NIFTY50'
  final String name; 
  final String category; // Stocks, ETFs, Mutual Funds, etc.
  final double currentPrice;
  final double priceChange;
  final double changePercentage;
  final DateTime lastUpdated;
  final List<double> history;

  MarketData({
    required this.symbol,
    required this.name,
    required this.category,
    required this.currentPrice,
    required this.priceChange,
    required this.changePercentage,
    required this.lastUpdated,
    this.history = const [],
  });
  
  MarketData copyWith({
    String? symbol,
    String? name,
    String? category,
    double? currentPrice,
    double? priceChange,
    double? changePercentage,
    DateTime? lastUpdated,
    List<double>? history,
  }) {
    return MarketData(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      category: category ?? this.category,
      currentPrice: currentPrice ?? this.currentPrice,
      priceChange: priceChange ?? this.priceChange,
      changePercentage: changePercentage ?? this.changePercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      history: history ?? this.history,
    );
  }
}

class InsuranceProduct {
  final String id;
  final String provider;
  final String planName;
  final String type; // Health, Term, Vehicle
  final double sumInsured;
  final double annualPremium;
  final String logoUrl;
  final List<String> benefits;

  InsuranceProduct({
    required this.id,
    required this.provider,
    required this.planName,
    required this.type,
    required this.sumInsured,
    required this.annualPremium,
    required this.logoUrl,
    this.benefits = const [],
  });
}

class PostOfficeScheme {
  final String id;
  final String name;
  final double interestRate;
  final int tenureYears;
  final String type; // MIS, NSC, KVP, SCSS
  final double minInvestment;

  PostOfficeScheme({
    required this.id,
    required this.name,
    required this.interestRate,
    required this.tenureYears,
    required this.type,
    required this.minInvestment,
  });
}
