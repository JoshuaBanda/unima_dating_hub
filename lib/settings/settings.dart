import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unima_dating_hub/users/user_characteristics/preferences.dart';
import 'package:unima_dating_hub/users/user_characteristics/user_characteristics_page.dart';
import 'package:unima_dating_hub/users/profile_page.dart';
import 'notification_settings_page.dart';

class SettingsPage extends StatefulWidget {
  final String currentUserId; // Accept the currentUserId parameter

  const SettingsPage({super.key, required this.currentUserId});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Variables to hold the user data
  String jwt_token = '';
  String currentUserId = '';
  String currentUserEmail = '';
  String firstName = '';
  String lastName = '';
  String profilePicture = '';
  bool activationStatus = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from secure storage
  void _fetchUserData() async {
    // Load user data from secure storage
    jwt_token = await _storage.read(key: 'jwt_token') ?? '';  // Corrected the key
    currentUserId = await _storage.read(key: 'userid') ?? '';
    currentUserEmail = await _storage.read(key: 'email') ?? '';
    firstName = await _storage.read(key: 'firstname') ?? '';
    lastName = await _storage.read(key: 'lastname') ?? '';
    profilePicture = await _storage.read(key: 'profilepicture') ?? '';
    String? activationStatusString =
        await _storage.read(key: 'activationstatus');
    activationStatus = activationStatusString == 'true';  // Convert string to boolean
    
    // Trigger a rebuild once the data is fetched
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: currentUserId.isEmpty
            ? const Center(child: CircularProgressIndicator()) // Show loading if data is not loaded
            : ListView(
                children: [
                  // Profile Section
                  ListTile(
                    leading: Icon(Icons.account_circle, color: Colors.grey),
                    title: Text('Profile: $firstName $lastName'),
                    subtitle: Text('Email: $currentUserEmail'),
                    onTap: () {
                      // Navigate to Profile Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyProfilePage(currentUserId: currentUserId, currentUserEmail: currentUserEmail, firstName: firstName, lastName: lastName, profilePicture: profilePicture, activationStatus: activationStatus)),
                      );
                    },
                  ),
                  const Divider(),

                  // Notifications Section
                  ListTile(
                    leading: Icon(Icons.notifications, color: Colors.grey),
                    title: const Text('Notifications'),
                    subtitle: const Text('Manage your notifications settings'),
                    onTap: () {
                      // Navigate to Notifications Settings
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationsSettingsPage(
                          userId: currentUserId,
                        )),
                      );
                    },
                  ),
                  const Divider(),

                  // Privacy Section
                  ListTile(
                    leading: Icon(Icons.lock, color: Colors.grey),
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
                    leading: Icon(Icons.email, color: Colors.grey),
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
                    leading: Icon(Icons.info, color: Colors.grey),
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
                    leading: Icon(Icons.people_alt, color: Colors.grey),
                    title: const Text('Preferences'),
                    subtitle: const Text('Set your preferences'),
                    onTap: () {
                      // Navigate to Preferences Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Preferences(userId: currentUserId)),
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
        child: Text('Account settings for User'),
      ),
    );
  }
}


