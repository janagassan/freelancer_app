// ===== frontend/lib/models/financial_model.dart =====
import 'dart:ui';

import 'package:flutter/material.dart';

class FinancialStats {
  final double totalEarnings;
  final double totalFees;
  final double totalWithdrawals;
  final double netEarnings;

  FinancialStats({
    required this.totalEarnings,
    required this.totalFees,
    required this.totalWithdrawals,
    required this.netEarnings,
  });

  factory FinancialStats.fromJson(Map<String, dynamic> json) {
    double parseToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          print('Error parsing "$value" to double: $e');
          return 0.0;
        }
      }
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return FinancialStats(
      totalEarnings: parseToDouble(json['totalEarnings']),
      totalFees: parseToDouble(json['totalFees']),
      totalWithdrawals: parseToDouble(json['totalWithdrawals']),
      netEarnings: parseToDouble(json['netEarnings']),
    );
  }
}

class FinancialTransaction {
  final int id;
  final double amount;
  final String type;
  final String status;
  final String? description;
  final DateTime transactionDate;
  final Map<String, dynamic>? metadata;

  FinancialTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    required this.transactionDate,
    this.metadata,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    double parseToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return FinancialTransaction(
      id: json['id'] ?? 0,
      amount: parseToDouble(json['amount']),
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      description: json['description'],
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : DateTime.now(),
      metadata: json['metadata'],
    );
  }

  bool get isIncome =>
      type == 'payment_received' || type == 'deposit' || type == 'bonus';

  bool get isExpense =>
      type == 'payment_sent' || type == 'withdrawal' || type == 'platform_fee';

  String get typeIcon {
    if (isIncome) return '💰';
    if (type == 'platform_fee') return '📝';
    return '💸';
  }

  Color get typeColor {
    if (isIncome) return Colors.green;
    if (type == 'platform_fee') return Colors.orange;
    return Colors.red;
  }
}

class SavedFilter {
  final int id;
  final String name;
  final Map<String, dynamic> filterData;
  final bool isDefault;
  final DateTime createdAt;

  SavedFilter({
    required this.id,
    required this.name,
    required this.filterData,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedFilter.fromJson(Map<String, dynamic> json) {
    return SavedFilter(
      id: json['id'],
      name: json['name'],
      filterData: json['filter_data'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class FinancialStatsResponse {
  final FinancialStats stats;
  final List<Map<String, dynamic>> periodStats;
  final List<FinancialTransaction> recentTransactions;

  FinancialStatsResponse({
    required this.stats,
    required this.periodStats,
    required this.recentTransactions,
  });

  factory FinancialStatsResponse.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parsePeriodStats(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }
      return [];
    }

    List<FinancialTransaction> parseTransactions(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data
            .map((tx) {
              try {
                return FinancialTransaction.fromJson(tx);
              } catch (e) {
                print('Error parsing transaction: $e');
                return null;
              }
            })
            .whereType<FinancialTransaction>()
            .toList();
      }
      return [];
    }

    return FinancialStatsResponse(
      stats: FinancialStats.fromJson(json['stats'] ?? {}),
      periodStats: parsePeriodStats(json['periodStats']),
      recentTransactions: parseTransactions(json['recentTransactions']),
    );
  }
}

class ProjectAlert {
  final int id;
  final String name;
  final List<String> keywords;
  final List<String> skills;
  final double? minBudget;
  final double? maxBudget;
  final List<String> categories;
  final bool isActive;
  final List<String> notificationMethods;

  ProjectAlert({
    required this.id,
    required this.name,
    required this.keywords,
    required this.skills,
    this.minBudget,
    this.maxBudget,
    required this.categories,
    required this.isActive,
    required this.notificationMethods,
  });

  factory ProjectAlert.fromJson(Map<String, dynamic> json) {
    return ProjectAlert(
      id: json['id'],
      name: json['name'],
      keywords: List<String>.from(json['keywords'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      minBudget: json['min_budget']?.toDouble(),
      maxBudget: json['max_budget']?.toDouble(),
      categories: List<String>.from(json['categories'] ?? []),
      isActive: json['is_active'] ?? true,
      notificationMethods: List<String>.from(
        json['notification_methods'] ?? ['email'],
      ),
    );
  }
}
