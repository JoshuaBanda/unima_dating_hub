import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart'; // Import cached_network_image
import 'profile_page.dart'; // Import ProfilePage widget
import 'full_screen_image_page.dart'; // Import FullScreenImage widget
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import flutter_spinkit
import 'package:google_fonts/google_fonts.dart'; // Import the Google Fonts package
import 'package:unima_dating_hub/users/user_characteristics/preferences.dart';

class ContactsScreen extends StatefulWidget {
  final String myUserId; // The ID of the logged-in user
  final String jwtToken; // Add jwtToken to ContactsScreen constructor

  const ContactsScreen({super.key, required this.myUserId, required this.jwtToken}); // Pass jwtToken

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool creatingInbox = false;
  int currentPage = 1;
  int pageSize = 10;
  List<dynamic> users = []; // Store users here
  Set<String> existingUserIds = Set(); // Track user IDs to prevent duplicates
  bool isLoading = false;

  // Fetch users from the API with pagination
  Future<void> fetchUsers() async {
    try {
      setState(() {
        isLoading = true; // Start loading
      });

      final response = await http.get(
        Uri.parse('https://datehubbackend.onrender.com/users/test?page=$currentPage&pageSize=$pageSize'),
        headers: {
          'Authorization': 'Bearer ${widget.jwtToken}', // Pass JWT token in the headers
        },
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final List<dynamic> fetchedUsers = json.decode(response.body);

        // Check if fetchedUsers is a list
        if (fetchedUsers is List) {
          List<dynamic> newUsers = fetchedUsers
              .map((item) => item['user'])
              .where((user) => user != null && !existingUserIds.contains(user['userid'].toString())) // Filter out already existing users
              .toList();

          // Add the new users to the existing list
          setState(() {
            users.addAll(newUsers); // Add new users to the list
            // Add user IDs to the Set to track them and prevent duplicates
            existingUserIds.addAll(newUsers.map((user) => user['userid'].toString()));
          });

          groupUsersBySimilarity(newUsers); // Group the users based on similarity
        } else {
          // If fetchedUsers is invalid, handle the error
          throw Exception('Received invalid data: fetchedUsers is null or not a list');
        }
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      // Log the error instead of print
      print('Error fetching users: $e');
      // Check if the error is related to missing preferences (you can customize this part depending on the error message)
      if (e.toString().contains('Failed to fetch users')) {
        _showPreferenceDialog(context); // Pass the context as an argument

      }
      throw Exception('Error fetching users: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  // Group users based on similarity criteria
  void groupUsersBySimilarity(List<dynamic> userList) {
    Map<String, List<dynamic>> groupedUsers = {};

    for (var user in userList) {
      if (user['matchedCriteria'] != null && user['matchedCriteria'].isNotEmpty) {
        for (var criterion in user['matchedCriteria']) {
          if (groupedUsers.containsKey(criterion)) {
            groupedUsers[criterion]?.add(user);
          } else {
            groupedUsers[criterion] = [user];
          }
        }
      }
    }

    // Log the grouped users
    print("Grouped Users: $groupedUsers");
  }

  @override
  void initState() {
    super.initState();
    fetchUsers(); // Fetch users when the screen is loaded
  }

  // Pagination: Load more users when the user scrolls to the bottom
  void loadMoreUsers() {
    setState(() {
      currentPage++;
    });
    fetchUsers(); // Fetch more users when the user scrolls
  }

  // Show a dialog asking the user to fill in their preferences

void _showPreferenceDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Optional: make it rounded
        backgroundColor: Colors.red.withOpacity(0.8), // Set red background with opacity
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content
            children: [
              const Text(
                "Missing Preferences",
                style: TextStyle(
                  color: Colors.white, // White text for the title
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "It looks like you haven't completed your preferences yet. Would you like to fill them now?",
                style: TextStyle(
                  color: Colors.white, // White text for the content
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white), // White text
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Preferences(userId: 'yourUserId'), // Adjust as needed
                        ),
                      );
                    },
                    child: const Text(
                      "Go to Preferences",
                      style: TextStyle(color: Colors.white), // White text
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollEndNotification &&
              scrollNotification.metrics.pixels == scrollNotification.metrics.maxScrollExtent) {
            loadMoreUsers(); // Load more users
          }
          return true;
        },
        child: isLoading && users.isEmpty
            ? const Center(
                child: SpinKitFadingCircle(color: Colors.grey, size: 50.0),
              ) // Show a progress indicator while loading
            : users.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
                    itemCount: users.length + (isLoading ? 1 : 0), // Show loading spinner at the end
                    itemBuilder: (context, index) {
                      if (index == users.length) {
                        // Show a loading spinner at the bottom if more users are being loaded
                        return const Center(child: SpinKitFadingCircle(color: Colors.grey, size: 50.0));
                      }

                      final user = users[index];
                      String profilePicture = user['profilepicture'] ?? ''; // Safely handle null profilePicture
                      return GestureDetector(
                        onTap: () {
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
                                jwtToken: widget.jwtToken, // Pass jwtToken here
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImage(
                                      imageUrl: profilePicture.isNotEmpty
                                          ? profilePicture
                                          : 'assets/default_profile.png',
                                    ),
                                  ),
                                );
                              },
                              child: profilePicture.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: profilePicture,
                                      imageBuilder: (context, imageProvider) =>
                                          CircleAvatar(radius: 30, backgroundImage: imageProvider),
                                      placeholder: (context, url) => const CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.grey,
                                        child: SpinKitFadingCircle(color: Colors.grey, size: 30.0),
                                      ),
                                      errorWidget: (context, url, error) => const CircleAvatar(
                                        radius: 30,
                                        backgroundImage: AssetImage('assets/default_profile.png'),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 30,
                                      backgroundImage: AssetImage('assets/default_profile.png'),
                                    ),
                            ),
                            title: Text(
                              '${user['firstname']} ${user['lastname']}',
                              style: GoogleFonts.montserrat(textStyle: TextStyle(fontSize: 18)),
                            ),
                            subtitle: Text(
                              'Tap to add friend',
                              style: GoogleFonts.dancingScript(textStyle: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: creatingInbox
          ? const Center(
              child: SpinKitFadingCircle(color: Colors.grey, size: 50.0))
          : null, // No spinner when not creating inbox
    );
  }
}
