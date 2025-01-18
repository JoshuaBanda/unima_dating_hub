import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:unima_dating_hub/home/home.dart'; // Make sure this screen exists

class BusinessNotificationsService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Global key to access the app's context for navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Initialize the plugin
  static Future<void> initialize() async {
    //print("Initializing BusinessNotificationsService...");
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
      'business_channel',
      'Business',
      description: 'This channel is used for business notifications.',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    //print("BusinessNotificationsService initialized.");
  }

  // Request notification permissions for Android 13+
  static Future<void> _requestNotificationPermission() async {
   // print("Requesting notification permission...");
    if (await Permission.notification.request().isGranted) {
     // print("Notification permission granted.");
    } else {
     // print("Notification permission denied.");
    }
  }

  // Handle notification response and navigate based on the payload
  static Future<void> onSelectNotification(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
     // print('Notification payload received: $payload');
      _navigateBasedOnPayload(payload);
    }
  }

  // Helper method to navigate based on the notification payload
  static void _navigateBasedOnPayload(String payload) {
   // print("Navigating based on payload...");
    // Decode the payload into a map (if it's a JSON string)
    Map<String, dynamic> payloadData = jsonDecode(payload);

    // Extract the data for navigation
    String businessId = payloadData['business_id'];
    String description = payloadData['description'];
    String photoUrl = payloadData['photo_url'];
    String userId = payloadData['user_id'];
    String senderName = payloadData['sender_name'];
    String senderProfilePicture = payloadData['sender_profile_picture'];
    String createdAt = payloadData['created_at'];

    //print("Navigating to business with ID: $businessId");

    // Navigate to the relevant screen (e.g., business details screen)
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => FarmSmartScreen(), // Assuming FarmSmartScreen is your screen for viewing businesses
      ),
    );
  }

  // Show notification with business details
  static Future<void> showNotification(
    String title,
    String body,
    String photoUrl,
    String businessId,
    String userId,
    String senderName,
    String senderProfilePicture,
    String createdAt,
  ) async {
    try {
     // print("Preparing to show notification for business ID: $businessId");

      String? largeIconPath;
      String? senderIconPath;

      // Download the business photo if available
      if (photoUrl.isNotEmpty) {
       // print("Downloading business photo...");
        final file = await _downloadAndSaveImage(photoUrl, businessId);
        if (file != null) {
          largeIconPath = file.path;
        //  print("Business photo downloaded and saved at: ${file.path}");
        } else {
        //  print("Failed to download business photo.");
        }
      }

      // Download the sender's profile picture
      if (senderProfilePicture.isNotEmpty) {
       // print("Downloading sender profile picture...");
        final senderFile = await _downloadAndSaveImage(senderProfilePicture, userId);
        if (senderFile != null) {
          senderIconPath = senderFile.path;
       //   print("Sender profile picture downloaded and saved at: ${senderFile.path}");
        } else {
        //  print("Failed to download sender's profile picture.");
        }
      }

      // BigPictureStyle to display the business image
      final BigPictureStyleInformation bigPictureStyleInformation =
          BigPictureStyleInformation(
        FilePathAndroidBitmap(largeIconPath ?? ''), // Large image for the business
        contentTitle: title, // Set the notification title
        summaryText: '$senderName: $body', // Include sender's name and message body
        htmlFormatContentTitle: true,
        htmlFormatSummaryText: true,
      );

      // Android notification settings
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'business_channel',
        'Business',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        icon: 'ic_launcher',
        styleInformation: bigPictureStyleInformation,
        largeIcon: senderIconPath != null
            ? FilePathAndroidBitmap(senderIconPath)
            : null, // Use sender's profile picture as large icon
      );

      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      // Create the payload with the new business fields including sender details
      String payload = jsonEncode({
        'business_id': businessId,
        'description': body,
        'photo_url': photoUrl,
        'user_id': userId,
        'sender_name': senderName,
        'sender_profile_picture': senderProfilePicture,
        'created_at': createdAt,
      });

     // print("Showing notification with payload: $payload");

      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        int.parse(businessId),
        title,
        '$senderName: $body', // Include sender's name and business message in the notification body
        platformChannelSpecifics,
        payload: payload, // Pass the payload directly
      );

     // print("Notification displayed successfully for business ID: $businessId.");
    } catch (e) {
     // print("Error displaying business notification: $e");
    }
  }

  // Helper method to download and save the image locally
  static Future<File?> _downloadAndSaveImage(String imageUrl, String businessId) async {
    try {
     // print("Downloading image from URL: $imageUrl");
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/business_image_$businessId.jpg';

      final file = File(filePath);
      if (await file.exists()) {
     //   print("Image already exists at: $filePath");
        return file;
      }

      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await file.writeAsBytes(bytes);
     //   print("Image saved to ${file.path}");
        return file;
      } else {
      //  print("Failed to download image, status code: ${response.statusCode}");
      }
    } catch (e) {
     // print("Error downloading image: $e");
    }
    return null;
  }

  // Schedule notification at a specific date/time
  static Future<void> scheduleNotification(DateTime scheduledDateTime) async {
    final location = tz.getLocation('America/New_York');
    final tzDateTime = tz.TZDateTime.from(scheduledDateTime, location);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'business_channel',
      'Business',
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
        'Scheduled Business Notification',
        'This is a scheduled business notification!',
        tzDateTime,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exact,
        payload: 'scheduled_message',
      );
    //  print("Scheduled business notification successfully.");
    } catch (e) {
    //  print("Error scheduling notification: $e");
    }
  }
}
