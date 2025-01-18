import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For parsing the response
import 'notification_model.dart' as custom_notification; // Import the custom Notification model
import 'notification_widget.dart'; // Import the NotificationWidget
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import flutter_spinkit

class NotificationsSettingsPage extends StatefulWidget {
  final String userId; // Assuming you have the user ID passed into this page

  NotificationsSettingsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _NotificationsSettingsPageState createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool isLoading = true;
  List<custom_notification.Notification> notifications = [];

  // Method to fetch notifications from the backend
  Future<void> fetchNotifications() async {
    final url =
        'https://datehubbackend.onrender.com/notifications/${widget.userId}';

    try {
      final response = await http.get(Uri.parse(url));
      //print("status code ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);  // Directly parse the response as a list
        //print("$data");

        setState(() {
          // Map over the list to create Notification objects
          notifications = data.map((notificationData) {
            return custom_notification.Notification(
              notificationText: notificationData['notification'],
              status: notificationData['status'],
              createdAt: DateTime.parse(notificationData['created_at']),
            );
          }).toList();
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
     // print('Error fetching notifications: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading once the request is complete
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications(); // Fetch notifications when the page is first loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
        title: Text('Search'),
        backgroundColor: Colors.white, // Set the app bar color
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey, // Set the underline to grey
            height: 1.0,
          ),
        ),
      
      ),
      body: isLoading
          ? Center(child:SpinKitFadingCircle(color: Colors.grey, size: 30.0),) // Show loading indicator
          : notifications.isEmpty
              ? Center(child: Text('No notifications available.'))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return NotificationWidget(
                        notification: notifications[index]);
                  },
                ),
    );
  }
}
