import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart'; // Import cached_network_image
import 'profile_page.dart'; // Import ProfilePage widget
import 'full_screen_image_page.dart'; // Import FullScreenImage widget
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import flutter_spinkit
import 'package:google_fonts/google_fonts.dart'; // Import the Google Fonts package

class ContactsScreen extends StatefulWidget {
  final String myUserId; // The ID of the logged-in user

  const ContactsScreen({super.key, required this.myUserId});

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool creatingInbox = false;

  // Fetch users from the API
  Future<List<dynamic>> fetchUsers() async {
    try {
      final response = await http
          .get(Uri.parse('https://datehubbackend.onrender.com/users/allusers'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contacts',
          style: GoogleFonts.dancingScript(
            textStyle: TextStyle(
              color: Colors.red, // You can adjust the color as needed
              fontStyle: FontStyle.italic, // Slanted look
              fontSize: 35,  // Adjust font size as per your preference
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitFadingCircle(color: Colors.grey, size: 50.0),
            ); // Show a progress indicator while loading
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          } else {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                String profilePicture = user['profilepicture'] ?? ''; // Safely handle null profilePicture
                print('profilepicture $profilePicture');
                return GestureDetector(
                  onTap: () {
                    // Navigate to ProfilePage when a user is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          profilePicture: profilePicture.isNotEmpty
                              ? profilePicture
                              : 'assets/default_profile.png', // Default image if null
                          firstName: user['firstname'],
                          lastName: user['lastname'],
                          currentUserId: widget.myUserId,
                          secondUserId: user['userid'].toString(),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0), // Add padding around each user
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          // Navigate to FullScreenImage when the profile picture is tapped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImage(
                                imageUrl: profilePicture.isNotEmpty
                                    ? profilePicture
                                    : 'assets/default_profile.png', // Use default image if null
                              ),
                            ),
                          );
                        },
                        child: profilePicture.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: profilePicture, // Load network image if available
                                imageBuilder: (context, imageProvider) =>
                                    CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      imageProvider, // Cached image from the URL
                                ),
                                placeholder: (context, url) =>
                                    const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors
                                      .grey, // Placeholder circle while loading
                                  child:
                                      CircularProgressIndicator(), // Spinner while loading image
                                ),
                                errorWidget: (context, url, error) =>
                                    const CircleAvatar(
                                  radius: 30,
                                  backgroundImage: AssetImage(
                                      'assets/default_profile.png'), // Fallback image if error
                                ),
                              )
                            : CircleAvatar(
                                radius: 30,
                                backgroundImage: AssetImage(
                                    'assets/default_profile.png'), // Default asset image
                              ),
                      ),
                      title: Text(
                        '${user['firstname']} ${user['lastname']}',
                        style: GoogleFonts.dancingScript(
                          textStyle: TextStyle(
                            fontStyle: FontStyle.italic, // Make the text slanted
                            fontSize: 25,  // Adjust the font size as needed
                          ),
                        ),
                      ),
                      subtitle: Text(
                        'Tap to view profile',
                        style: GoogleFonts.dancingScript(
                          textStyle: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 16, // Adjust font size as needed
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      // Show the spinner while creating inbox
      floatingActionButton: creatingInbox
          ? const Center(
              child: SpinKitFadingCircle(color: Colors.grey, size: 50.0))
          : null, // No spinner when not creating inbox
    );
  }
}
