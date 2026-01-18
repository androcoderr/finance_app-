import 'package:flutter/material.dart';
import '../../../models/chart_data.dart';
import '../../../view_model/home_view_model.dart';

Widget buildChartsSection(HomeViewModel viewModel, BuildContext context) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildChartCard(
              context,
              'Bu Ay Gelirler',
              viewModel.totalIncomeThisMonthPublic,
              viewModel.incomeData,
              Colors.green,
              Icons.trending_up,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildChartCard(
              context,
              'Bu Ay Giderler',
              viewModel.totalExpenseThisMonthPublic,
              viewModel.expenseData,
              Colors.red,
              Icons.trending_down,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildChartCard(
  BuildContext context,
  String title,
  double total,
  List<ChartData> data,
  Color color,
  IconData icon,
) {
  ThemeData theme = Theme.of(context);
  return Container(
    padding: EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.canvasColor,
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
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          '₺${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 12),
        SizedBox(height: 90, child: _buildMiniChart(data)),
      ],
    ),
  );
}

Widget _buildMiniChart(List<ChartData> data) {
  if (data.isEmpty) {
    return Center(
      child: Text(
        'Bu ay veri yok',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
    );
  }

  final double total = data.fold(0.0, (sum, item) => sum + item.amount);
  if (total == 0) {
    return Center(
      child: Text(
        'Bu ay veri yok',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
    );
  }

  final items = data.take(3).toList();

  return Column(
    children: items.map((item) {
      final percent = (item.amount / total) * 100;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                item.categoryName,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
            Text(
              '₺${item.amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 8),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
