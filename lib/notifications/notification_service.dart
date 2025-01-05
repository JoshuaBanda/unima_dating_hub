import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize the plugin
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher'); // Make sure it's in mipmap

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );
  }

  // Callback when the user taps on a notification
  static Future<void> onSelectNotification(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      print('Notification payload: $payload');
    }
  }

  // Show notification
  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'message_channel',
      'Messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: 'ic_launcher', // Ensure this is in the mipmap folders
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: 'new_message',  // Payload to use for additional data
      );
      print("Notification displayed successfully.");
    } catch (e) {
      print("Error displaying notification: $e");
    }
  }

  // Schedule notification
  static Future<void> scheduleNotification(DateTime scheduledDateTime) async {
    // Convert DateTime to TZDateTime
    final location = tz.getLocation('America/New_York'); // Change this to your preferred timezone
    final tzDateTime = tz.TZDateTime.from(scheduledDateTime, location);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'message_channel',
      'Messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: 'ic_launcher',  // Correct icon setup for scheduled notifications
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Scheduled Notification',
        'This is a scheduled notification!',
        tzDateTime, // Use TZDateTime here
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exact,  // Correct constant for exact scheduling
        payload: 'scheduled_message',
      );
      print("Scheduled notification successfully.");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }
}
