import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home/landingpage.dart';
import 'user_verification/Login_SignUp.dart';
import 'home/home.dart';
import 'posts/post_list.dart';
import 'users/user_characteristics/user_characteristics_page.dart';
import 'package:unima_dating_hub/users/user_characteristics/update_user_characteristics_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = FlutterSecureStorage();

  // Check if JWT token, email, and user ID are stored
  String? token = await storage.read(key: 'jwt_token');
  String? email = await storage.read(key: 'email');
  String? userId = await storage.read(key: 'userid');

  // For now, we use hardcoded values for firstName, lastName, profilePicture, and activationStatus
  String firstName = 'John'; // Example, you can replace this with real data
  String lastName = 'Doe'; // Example, replace with actual data
  String profilePicture = ''; // You may need to fetch this from storage or API
  bool activationStatus =
      true; // This should be retrieved from your API or storage

  // If a valid token exists, navigate directly to the home page
  runApp(MyApp(
    isLoggedIn: token != null && email != null && userId != null,
    userEmail: email,
    userId: userId,
    firstName: firstName,
    lastName: lastName,
    profilePicture: profilePicture,
    activationStatus: activationStatus,
    jwtToken: token ?? '',  // Pass the jwtToken here
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userEmail;
  final String? userId;
  final String firstName;
  final String lastName;
  final String profilePicture;
  final bool activationStatus;
  final String jwtToken; // Add the jwtToken parameter

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.userEmail,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.activationStatus,
    required this.jwtToken,  // Receive jwtToken
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/landingpage',
      routes: {
        '/home': (context) => FarmSmartScreen(),
        '/login': (context) => const LoginPage(),
        '/landingpage': (context) => const LandingPage(),
        '/land': (context) =>
            PostListPage(
              currentUserId: int.tryParse(userId ?? '0') ?? 0, 
              currentEmail: userEmail ?? '', 
              jwtToken: jwtToken), // Pass jwtToken here
        
        '/cr': (context) => UserCharacteristicsPage(userId: userId ?? '1'),
        
        '/cr2': (context) => UpdateFieldPage(userId: userId ?? '1'),
      },
    );
  }
}
