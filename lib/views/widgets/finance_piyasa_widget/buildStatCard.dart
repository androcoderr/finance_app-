import 'package:flutter/material.dart';

Widget buildStatCard(
  String title,
  String value,
  IconData icon, [
  Color? color,
]) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 20),
        SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 11)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
