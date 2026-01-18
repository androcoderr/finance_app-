import 'goal_model.dart';

class GoalAnalysis {
  final Goal goal;
  final double progress;
  final double remainingAmount;
  final int? remainingDays;
  final bool isCompleted;

  GoalAnalysis({
    required this.goal,
    required this.progress,
    required this.remainingAmount,
    this.remainingDays,
    required this.isCompleted,
  });
}
