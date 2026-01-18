import 'package:flutter/material.dart';
import '../../../view_model/home_view_model.dart';

Widget buildGoalsSection(HomeViewModel viewModel) {
  if (viewModel.goals.isEmpty) return SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Hedeflerim',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
      SizedBox(height: 12),
      SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: viewModel.goals.length,
          itemBuilder: (context, index) {
            final goal = viewModel.goals[index];
            return Container(
              width: 200,
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, color: Colors.blue[600], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          goal.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${viewModel.formatCurrency(goal.currentAmount)} / ${viewModel.formatCurrency(goal.targetAmount)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: goal.progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.progress >= 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${(goal.progress * 100).toStringAsFixed(1)}% tamamlandı',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}
