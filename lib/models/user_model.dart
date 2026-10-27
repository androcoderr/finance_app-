import 'package:flutter/foundation.dart';
import 'transaction_model.dart';
import 'goal_model.dart';
import 'budget_model.dart';
import 'recurring_transaction_model.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final List<TransactionModel> transactions;
  final List<Goal> goals;
  final List<Budget> budgets;
  final List<RecurringTransaction> recurringTransactions;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.transactions,
    required this.goals,
    required this.budgets,
    required this.recurringTransactions,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    List<TransactionModel>? transactions,
    List<Goal>? goals,
    List<Budget>? budgets,
    List<RecurringTransaction>? recurringTransactions,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      transactions: transactions ?? this.transactions,
      goals: goals ?? this.goals,
      budgets: budgets ?? this.budgets,
      recurringTransactions:
          recurringTransactions ?? this.recurringTransactions,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Tekrarlayan işlemler: bozuk bir kayıt diğerlerini engellemesin
    final recurringList = <RecurringTransaction>[];
    final rawRecurring = json['recurring_transactions'];
    if (rawRecurring is List) {
      for (final item in rawRecurring) {
        try {
          if (item is Map) {
            recurringList.add(
              RecurringTransaction.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        } catch (e) {
          debugPrint('Tekrarlayan işlem okunamadı: $e');
        }
      }
    }

    final user = User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      transactions:
          (json['transactions'] as List?)
              ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      goals:
          (json['goals'] as List?)
              ?.map((e) => Goal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      budgets:
          (json['budgets'] as List?)
              ?.map((e) => Budget.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recurringTransactions: recurringList,
    );


    return user;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    // Şifre cihazda saklanmaz
    'transactions': transactions.map((e) => e.toJson()).toList(),
    'goals': goals.map((e) => e.toJson()).toList(),
    'budgets': budgets.map((e) => e.toJson()).toList(),
    'recurring_transactions': recurringTransactions
        .map((e) => e.toJson())
        .toList(),
  };
}
