import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:unima_dating_hub/chats/messages/chat_messages.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Global key to access the app's context for navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Initialize the plugin
  static Future<void> initialize() async {
    //print("Initializing notification service...");
    tz_data.initializeTimeZones();

    // Request notification permission
    await _requestNotificationPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher'); // Ensure this is your icon name

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'message_channel',
      'Messages',
      description: 'This channel is used for messaging notifications.',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    //print("Notification service initialized.");
  }

  // Request notification permissions for Android 13+
  static Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.request().isGranted) {
      //print('Notification permission granted');
    } else {
      //print('Notification permission denied');
    }
  }

  // Handle notification response and navigate based on the payload
  static Future<void> onSelectNotification(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      //print('Notification payload: $payload');
      // Navigate based on the payload, pass the navigator key instead of context
      _navigateBasedOnPayload(payload);
    }
  }

  // Helper method to navigate based on the notification payload
  static void _navigateBasedOnPayload(String payload) {
    // Decode the payload into a map (if it's a JSON string)
    Map<String, dynamic> payloadData = jsonDecode(payload);

    // Extract the data for navigation
    String userId = payloadData['userId'];
    String myUserId = payloadData['myUserId'];
    String firstName = payloadData['firstName'];
    String lastName = payloadData['lastName'];
    String profilePicture = payloadData['profilePicture'];
    String inboxId = payloadData['inboxId'];

    // Navigate to the Chills screen with the extracted data
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => Chills(
          userId: userId,
          myUserId: myUserId,
          firstName: firstName,
          lastName: lastName,
          profilePicture: profilePicture,
          inboxid: inboxId,
        ),
      ),
    );
  }

  // Show notification with profile photo and dynamic ID
  static Future<void> showNotification(
    String title,
    String body,
    String profilePhotoUrl,
    String userId,
    String notificationId, // Notification ID
    String myUserId,       // Current user's ID
    String firstName,      // First Name
    String lastName,
    String inboxId,    
  ) async {
    try {
      //print("Preparing to show notification with title: $title");
      String? largeIconPath;

      if (profilePhotoUrl.isNotEmpty) {
        //print("Profile photo URL provided, downloading image...");
        final file = await _downloadAndSaveImage(profilePhotoUrl, userId);
        if (file != null) {
          largeIconPath = file.path;
          //print("Image downloaded and saved at: ${file.path}");
        } else {
          //print("Failed to download profile photo.");
        }
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'message_channel',
        'Messages',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        icon: 'ic_launcher',
        largeIcon: largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

      // No payload here, you can directly pass the parameters
      String payload = jsonEncode({
        'userId': userId,
        'myUserId': myUserId,
        'firstName': firstName,
        'lastName': lastName,
        'profilePicture': profilePhotoUrl,
        'inboxId': inboxId,
      });

      await flutterLocalNotificationsPlugin.show(
        int.parse(notificationId),
        title,
        body,
        platformChannelSpecifics,
        payload: payload, // Pass the payload directly
      );
      //print("Notification displayed successfully.");
    } catch (e) {
      //print("Error displaying notification: $e");
    }
  }

  // Helper method to download and save the image locally
  static Future<File?> _downloadAndSaveImage(String imageUrl, String userId) async {
    try {
      //print("Downloading image from URL: $imageUrl");
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/profile_photo_$userId.jpg';

      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }

      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e) {
      //print("Error downloading image: $e");
    }
    return null;
  }

  // Schedule notification at a specific date/time
  static Future<void> scheduleNotification(DateTime scheduledDateTime) async {
    final location = tz.getLocation('America/New_York');
    final tzDateTime = tz.TZDateTime.from(scheduledDateTime, location);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'message_channel',
      'Messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: 'ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Scheduled Notification',
        'This is a scheduled notification!',
        tzDateTime,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exact,
        payload: 'scheduled_message',
      );
      //print("Scheduled notification successfully.");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }
}
