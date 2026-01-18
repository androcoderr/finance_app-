import 'package:flutter/material.dart';

import '../../../view_model/finance_view_model.dart';

Widget buildErrorWidget(FinanceViewModel viewModel) {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Bir hata oluştu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            viewModel.errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: viewModel.retryLastOperation,
            icon: Icon(Icons.refresh),
            label: Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
