import 'package:flutter/material.dart';

import '../../../view_model/home_view_model.dart';

Widget buildWelcomeSection(HomeViewModel viewModel) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue[400]!, Colors.blue[600]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoş geldin,',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                viewModel.currentUser!.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.person_outline, color: Colors.white, size: 32),
      ],
    ),
  );
}
