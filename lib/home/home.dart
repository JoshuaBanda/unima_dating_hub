import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:unima_dating_hub/chats/contacts_screen.dart';
import 'HomeScreen.dart'; // Import HomeScreen
import 'search_page.dart';
import '/chats/chats.dart';
import '/user_verification/Login_SignUp.dart';
import '/users/profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unima_dating_hub/posts/create_post_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // Import AnimatedTextKit
import 'package:unima_dating_hub/users/user_characteristics/update_user_characteristics_page.dart';
import 'package:unima_dating_hub/confessions/main_confession_page.dart';
import 'package:unima_dating_hub/settings/settings.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FarmSmartScreen extends StatefulWidget {
  @override
  _FarmSmartScreenState createState() => _FarmSmartScreenState();
}

class _FarmSmartScreenState extends State<FarmSmartScreen> {
  int _currentIndex = 0; // Track the current index for BottomNavigationBar
  DateTime? _lastPressedAt;

  // User Data fetched from FlutterSecureStorage
  String currentUserId = '';
  String currentUserEmail = '';
  String firstName = '';
  String lastName = '';
  String profilePicture = '';
  bool activationStatus = false;
  String jwt_token = ''; // Declare the jwt_token variable

  // Initialize FlutterSecureStorage
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Flag to indicate if data is loaded and waiting for the delay
  bool isDataLoaded = false;

  // Fetch user data from FlutterSecureStorage when the screen is initialized
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch the stored user data from secure storage
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
    activationStatus = activationStatusString == 'true';

    // Wait for 2 seconds to simulate a loading period
    await Future.delayed(Duration(seconds: 2));

    // After the delay, update the state to indicate that the data is ready
    setState(() {
      isDataLoaded = true; // Mark data as loaded
    });
  }

  // Handle logout action
  void _handleLogout(BuildContext context) async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'userid');
    await _storage.delete(key: 'firstname');
    await _storage.delete(key: 'lastname');
    await _storage.delete(key: 'profilepicture');
    await _storage.delete(key: 'activationstatus');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Navigation for the menu items (Logout)
  void _onMenuPressed() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1.0, 80.0, 0.0, 0.0),
      items: [
        const PopupMenuItem(
          value: 'logout',
          child: Text(
            'Logout',
            style: TextStyle(color: Colors.black),
          ),
        ),
        PopupMenuItem(
          value: 'navigate', // Add this item for navigation
          child: Text(
            'settings', // The option text
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value != null) {
        if (value == 'logout') {
          _handleLogout(context); // Handle the logout logic
        } else if (value == 'navigate') {
          _navigateToNewPage(context); // Navigate to the new page
        }
      }
    });
  }

  // Function to navigate to the new page
  void _navigateToNewPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(currentUserId: currentUserId)
      ),
    );
  }

  // This function handles the back button press logic
  Future<bool> _onWillPop() async {
    // If the user is in the home screen, we check if they pressed back twice
    if (_currentIndex == 0) {
      if (_lastPressedAt == null ||
          DateTime.now().difference(_lastPressedAt!) > Duration(seconds: 2)) {
        // User pressed back once, show a message to press again to exit
        _lastPressedAt = DateTime.now();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
        return false; // Prevent exiting
      }
      return true; // Exit the app if pressed back again within 2 seconds
    }

    // If user is not on the home screen, pop to home
    setState(() {
      _currentIndex = 0; // Switch to home screen
    });
    return false; // Prevent normal back action
  }

  @override
  Widget build(BuildContext context) {
    // If data is not loaded yet, show the loading screen with a red-orange gradient background
    if (!isDataLoaded) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 255, 162, 156),
                const Color.fromARGB(255, 255, 230, 193)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "UNIMA DATES", // Text to display
                  style: GoogleFonts.montserrat(
                    textStyle: TextStyle(
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            Colors.pink,
                            Colors.red
                          ],
                        ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                      fontStyle: FontStyle.italic, // Italic font style
                      fontSize: 32, // Font size set to 32
                    ),
                  ),
                ),
                SizedBox(height: 20), // Space between the text and the dots
                // Animated dots progress indicator
                AnimatedTextKit(
                  animatedTexts: [
                    TyperAnimatedText(
                      "Get your match",
                      textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(248, 255, 102, 1),
                      ),
                    ),
                    TyperAnimatedText(
                      "....",
                      textStyle: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  totalRepeatCount: 2, // Repeat the animation a few times
                  pause: Duration(
                      milliseconds: 500), // Pause between animation loops
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If data is loaded, display the actual content
    return WillPopScope(
      onWillPop: _onWillPop, // Intercept the back button press
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "$firstName $lastName",
            style: GoogleFonts.dancingScript(
              textStyle: TextStyle(
                color: Colors.red,
                fontStyle: FontStyle.italic,
                fontSize: 28,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchPage(),
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyProfilePage(
                      currentUserId: currentUserId,
                      currentUserEmail: currentUserEmail,
                      firstName: firstName,
                      lastName: lastName,
                      profilePicture: profilePicture,
                      activationStatus: activationStatus,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(profilePicture),
                backgroundColor: Colors.grey[300],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: _onMenuPressed,
            ),
          ],
        ),
        body: Column(
          children: [
            const Divider(height: 1, color: Colors.grey, thickness: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  // Pass the currentUserEmail and jwtToken to HomeScreen as required
                  HomeScreen(
                    currentUserId: currentUserId.isNotEmpty
                        ? int.tryParse(currentUserId) ?? 0
                        : 0, // Safely parse or default to 0
                    currentEmail: currentUserEmail, // Pass currentUserEmail
                    jwtToken: jwt_token,  // Pass jwtToken here
                  ),
                  Chats(myUserId: currentUserId,jwtToken: jwt_token,),
                  const SizedBox.shrink(),
                  ContactsScreen(myUserId: currentUserId,jwtToken: jwt_token,),
                  AnonymousConfessionPage(jwtToken: jwt_token, currentUserId: int.tryParse(currentUserId)??0 , currentEmail: currentUserEmail),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(255, 239, 237, 237),
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey[800],
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePostPage(userId: currentUserId),
                ),
              );
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: "Chats",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 30),
              label: "Add Post",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "Friends",
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.masksTheater),
              label: "confessions",
            ),
          ],
        ),
      ),
    );
  }
}
