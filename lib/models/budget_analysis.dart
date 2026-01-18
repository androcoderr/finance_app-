// Yardımcı sınıflar
import 'budget_model.dart';

class BudgetAnalysis {
  final Budget budget;
  final double spentAmount;
  final double remainingAmount;
  final double percentage;
  final bool isOverBudget;

  BudgetAnalysis({
    required this.budget,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentage,
    required this.isOverBudget,
  });
}
