import 'package:flutter/material.dart';
import 'package:unima_dating_hub/user_verification/Login_SignUp.dart';

class PreferencesScreen extends StatefulWidget {
  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _notificationsEnabled = true; // Default value for notifications
  bool _darkModeEnabled = false; // Default value for dark mode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preferences"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Notification Preference
            SwitchListTile(
              title: Text(
                'Enable Notifications',
                style: TextStyle(fontSize: 18),
              ),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: Colors.red,
            ),

            // Dark Mode Preference
            SwitchListTile(
              title: Text(
                'Enable Dark Mode',
                style: TextStyle(fontSize: 18),
              ),
              value: _darkModeEnabled,
              onChanged: (bool value) {
                setState(() {
                  _darkModeEnabled = value;
                });
                // Implement dark mode toggle logic here (for example, change theme)
              },
              activeColor: Colors.red,
            ),

            // Log Out Button
            ListTile(
              title: Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                _showLogoutConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show a confirmation dialog when the user attempts to log out
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _handleLogout(context); // Implement logout action
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Log Out'),
          ),
        ],
      ),
    );
  }

  // Handle logout action (delete tokens, navigate to login)
  void _handleLogout(BuildContext context) {
    // Add your logout code here (e.g., delete JWT token, navigate to login screen)
    // For example:
    // final FlutterSecureStorage storage = FlutterSecureStorage();
    // await storage.delete(key: 'jwt_token');
    // await storage.delete(key: 'email');
    // await storage.delete(key: 'userid');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Replace with your LoginPage widget
    );
  }
}
