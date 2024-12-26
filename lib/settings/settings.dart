import 'package:flutter/material.dart';
import 'package:unima_dating_hub/users/user_characteristics/preferences.dart';
import 'package:unima_dating_hub/users/user_characteristics/update_user_characteristics_page.dart';
import 'package:unima_dating_hub/users/user_characteristics/user_characteristics_page.dart';

class SettingsPage extends StatelessWidget {
  final String currentUserId; // Accept the currentUserId parameter

  const SettingsPage({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Profile Section
            ListTile(
              leading: Icon(Icons.account_circle, color: Colors.blueAccent),
              title: const Text('Profile'),
              subtitle: const Text('View and update your profile'),
              onTap: () {
                // Navigate to Profile Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(currentUserId: currentUserId)),
                );
              },
            ),
            const Divider(),

            // Notifications Section
            ListTile(
              leading: Icon(Icons.notifications, color: Colors.blueAccent),
              title: const Text('Notifications'),
              subtitle: const Text('Manage your notifications settings'),
              onTap: () {
                // Navigate to Notifications Settings
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsSettingsPage()),
                );
              },
            ),
            const Divider(),

            // Privacy Section
            ListTile(
              leading: Icon(Icons.lock, color: Colors.blueAccent),
              title: const Text('Privacy'),
              subtitle: const Text('Control your privacy settings'),
              onTap: () {
                // Navigate to Privacy Settings
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
                );
              },
            ),
            const Divider(),

            // Account Settings Section
            ListTile(
              leading: Icon(Icons.email, color: Colors.blueAccent),
              title: const Text('Account Settings'),
              subtitle: const Text('Change your email and password'),
              onTap: () {
                // Navigate to Account Settings page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountSettingsPage(currentUserId: currentUserId)),
                );
              },
            ),
            const Divider(),

            // User Bio Section
            ListTile(
              leading: Icon(Icons.info, color: Colors.blueAccent),
              title: const Text('User Bio'),
              subtitle: const Text('View and update your bio'),
              onTap: () {
                // Navigate to User Bio Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserCharacteristicsPage(userId: currentUserId)),
                );
              },
            ),
            const Divider(),

            // Preferences Section
            ListTile(
              leading: Icon(Icons.settings, color: Colors.blueAccent),
              title: const Text('Preferences'),
              subtitle: const Text('Set your preferences'),
              onTap: () {
                // Navigate to Preferences Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>Preferences(userId: currentUserId)),
                );
              },
            ),
            const Divider(),

            // Logout Section
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Logout'),
              subtitle: const Text('Log out from the app'),
              onTap: () {
                // Perform logout action
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to handle logout
  void _logout(BuildContext context) {
    // Handle the logout logic (e.g., clear session, navigate to login screen)
    // For demonstration, we'll just show a snackbar and pop to the login screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully!')),
    );
    Navigator.pop(context);  // Pop back to the previous screen or login screen
  }
}

// Dummy Profile Page
class ProfilePage extends StatelessWidget {
  final String currentUserId;

  const ProfilePage({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Text('Profile for User ID: $currentUserId'),
      ),
    );
  }
}

// Dummy Notifications Settings Page
class NotificationsSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications Settings')),
      body: Center(
        child: const Text('Manage your notification preferences here.'),
      ),
    );
  }
}

// Dummy Privacy Settings Page
class PrivacySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: Center(
        child: const Text('Adjust your privacy settings here.'),
      ),
    );
  }
}

// Dummy Account Settings Page
class AccountSettingsPage extends StatelessWidget {
  final String currentUserId;

  const AccountSettingsPage({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: Center(
        child: Text('Account settings for User ID: $currentUserId'),
      ),
    );
  }
}

// User Bio Page
class UserBioPage extends StatelessWidget {
  final String currentUserId;

  const UserBioPage({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Bio')),
      body: Center(
        child: Text('User Bio for User ID: $currentUserId'),
      ),
    );
  }
}

// Preferences Page
class PreferencesPage extends StatelessWidget {
  final String currentUserId;

  const PreferencesPage({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: Center(
        child: Text('Preferences for User ID: $currentUserId'),
      ),
    );
  }
}
