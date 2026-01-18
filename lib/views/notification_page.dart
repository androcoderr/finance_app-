// lib/views/pages/notification_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../view_model/notification_provider.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              if (notificationProvider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline),
                        const SizedBox(width: 8),
                        const Text('Tümünü Okundu İşaretle'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Tümünü Temizle'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    notificationProvider.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "Tüm bildirimler okundu olarak işaretlendi",
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );
                  } else if (value == 'clear_all') {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Tüm Bildirimleri Sil'),
                        content: const Text(
                          'Tüm bildirimleri silmek istediğinizden emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () {
                              notificationProvider.clearAllNotifications();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "Tüm bildirimler silindi",
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                              );
                            },
                            child: const Text(
                              'Sil',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Hiç bildirim yok",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Anomali tespit edildiğinde burada göreceksiniz",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notificationProvider.notifications.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final notification = notificationProvider.notifications[index];

              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  notificationProvider.removeNotification(notification.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Bildirim silindi"),
                      duration: const Duration(seconds: 2),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                },
                background: Container(
                  color: Colors.red.shade400,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  color: theme.cardTheme.color,
                  shape: theme.cardTheme.shape,
                  elevation: theme.cardTheme.elevation,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notification.isAnomaly
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notification.isAnomaly
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: notification.isAnomaly
                            ? Colors.orange
                            : Colors.green,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600, // Okunmamışsa kalın
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTimestamp(notification.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    trailing: Icon(
                      notification.isRead
                          ? Icons.check_circle_outline
                          : (notification.isAnomaly
                                ? Icons.error_outline
                                : Icons.info_outline),
                      color: notification.isRead
                          ? Colors.green
                          : (notification.isAnomaly
                                ? Colors.orange
                                : Colors.blue),
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () {
                      // Bildirime tıklayınca okundu olarak işaretle
                      if (!notification.isRead) {
                        notificationProvider.markAsRead(notification.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
