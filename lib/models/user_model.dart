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
    print('\n========================================');
    print('🔧 [User.fromJson] Starting parse...');
    print('========================================');
    print('📦 JSON keys: ${json.keys}');
    print(
      '📦 Has recurring_transactions: ${json.containsKey('recurring_transactions')}',
    );

    // Recurring transactions'ı parse et
    List<RecurringTransaction> recurringList = [];

    if (json['recurring_transactions'] != null) {
      print('\n🔍 [RECURRING TRANSACTIONS] Starting parse...');
      final rawRecurring = json['recurring_transactions'];
      print('   Type: ${rawRecurring.runtimeType}');
      print('   Raw data: $rawRecurring');

      if (rawRecurring is List) {
        print('   ✓ Is List with ${rawRecurring.length} items');

        for (var i = 0; i < rawRecurring.length; i++) {
          try {
            print('\n   --- Item #$i ---');
            var item = rawRecurring[i];
            print('   Type: ${item.runtimeType}');
            print('   Data: $item');

            if (item is Map<String, dynamic>) {
              print('   ✓ Is Map<String, dynamic>');
              recurringList.add(RecurringTransaction.fromJson(item));
            } else if (item is Map) {
              print('   ⚠ Is Map (not String, dynamic), converting...');
              Map<String, dynamic> converted = Map<String, dynamic>.from(item);
              recurringList.add(RecurringTransaction.fromJson(converted));
            } else {
              print('   ❌ Unknown type: ${item.runtimeType}');
            }
          } catch (e, stackTrace) {
            print('   ❌ ERROR parsing item #$i: $e');
            print('   Stack: $stackTrace');
          }
        }
      } else {
        print('   ❌ Not a List! Type: ${rawRecurring.runtimeType}');
      }
    } else {
      print('\n⚠️ [RECURRING TRANSACTIONS] Key not found or null');
    }

    print('\n📊 [RECURRING TRANSACTIONS] Parse complete:');
    print('   Total parsed: ${recurringList.length}');
    if (recurringList.isNotEmpty) {
      print('   Items:');
      for (var rec in recurringList) {
        print('     - ${rec.description}: ${rec.amount} TL (${rec.type})');
      }
    }

    print('\n🔧 [User.fromJson] Creating User object...');

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

    print('\n✅ [User.fromJson] Complete!');
    print('   Name: ${user.name}');
    print('   Transactions: ${user.transactions.length}');
    print('   Goals: ${user.goals.length}');
    print('   Budgets: ${user.budgets.length}');
    print('   Recurring: ${user.recurringTransactions.length}');
    print('========================================\n');

    return user;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'transactions': transactions.map((e) => e.toJson()).toList(),
    'goals': goals.map((e) => e.toJson()).toList(),
    'budgets': budgets.map((e) => e.toJson()).toList(),
    'recurring_transactions': recurringTransactions
        .map((e) => e.toJson())
        .toList(),
  };
}
