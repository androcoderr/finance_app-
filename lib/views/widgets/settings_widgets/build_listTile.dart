import 'package:flutter/material.dart';

Widget buildListTile(
  BuildContext context, {
  required String title,
  String? subtitle,
  required IconData icon,
  VoidCallback? onTap,
  Color? color,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Material(
    color: colorScheme.surface,
    child: ListTile(
      leading: Icon(icon, color: color ?? colorScheme.primary),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    ),
  );
}
