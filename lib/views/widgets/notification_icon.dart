import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/notification_provider.dart';

class NotificationIconWithBadge extends StatelessWidget {
  const NotificationIconWithBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;

        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    child: unreadCount > 9
                        ? Center(
                            child: Text(
                              '9+',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
