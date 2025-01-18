import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unima_dating_hub/notifications/business_notifications_service.dart';
import 'home/landingpage.dart';
import 'user_verification/Login_SignUp.dart';
import 'home/home.dart';
import 'posts/post_list.dart';
import 'users/user_characteristics/user_characteristics_page.dart';
import '/users/user_characteristics/update_user_characteristics_page.dart';
import 'notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz_data.initializeTimeZones(); // Correct timezone initialization

  // Initialize notifications
  await NotificationService.initialize(); // Initialize Notification Service
  await BusinessNotificationsService.initialize();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(), // Start with Splash Screen
  ));
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final storage = FlutterSecureStorage();

    try {
      // Check if JWT token, email, and user ID are stored
      String? token = await storage.read(key: 'jwt_token');
      String? email = await storage.read(key: 'email');
      String? userId = await storage.read(key: 'userid');

      // For now, we use hardcoded values for firstName, lastName, profilePicture, and activationStatus
      String firstName = 'John';
      String lastName = 'Doe';
      String profilePicture = '';
      bool activationStatus = true;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyApp(
            isLoggedIn: token != null && email != null && userId != null,
            userEmail: email,
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            profilePicture: profilePicture,
            activationStatus: activationStatus,
            jwtToken: token ?? '',
          ),
        ),
      );
    } catch (e) {
      print("Error during app initialization: $e");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ErrorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Main App
class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userEmail;
  final String? userId;
  final String firstName;
  final String lastName;
  final String profilePicture;
  final bool activationStatus;
  final String jwtToken;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.userEmail,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.activationStatus,
    required this.jwtToken,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/landingpage',
      routes: {
        '/home': (context) => FarmSmartScreen(),
        '/login': (context) => const LoginPage(),
        '/landingpage': (context) => const LandingPage(),
        '/land': (context) => PostListPage(
              currentUserId: int.tryParse(userId ?? '0') ?? 0,
              currentEmail: userEmail ?? '',
              jwtToken: jwtToken,
            ),
        '/cr': (context) => UserCharacteristicsPage(userId: userId ?? '1'),
        '/cr2': (context) => UpdateFieldPage(userId: userId ?? '1'),
      },
    );
  }
}

// Error screen in case of initialization failure
class ErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Something went wrong during app initialization.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
