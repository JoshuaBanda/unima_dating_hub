import 'package:flutter/material.dart';
import 'notification_model.dart' as custom_notification; // Use alias for custom Notification class

class NotificationWidget extends StatelessWidget {
  final custom_notification.Notification notification;

  const NotificationWidget({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          notification.notificationText, // Corrected field name
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Status: ${notification.status} | ${notification.createdAt.toLocal()}',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: Icon(
          notification.status == 'seen' ? Icons.visibility : Icons.visibility_off,
          color: notification.status == 'seen' ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
