class Notification {
  final String notificationText; // The text for the notification
  final String status; // "seen" or "received"
  final DateTime createdAt; // The time the notification was created

  Notification({
    required this.notificationText, // Field name matches this
    required this.status,
    required this.createdAt,
  });
}
