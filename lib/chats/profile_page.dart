import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:unima_dating_hub/posts/profile_post_list_page.dart'; // Import your ProfilePostListPage widget
import 'inbox_messages.dart'; // Assuming this is your chat screen widget

class ProfilePage extends StatefulWidget {
  final String profilePicture;
  final String firstName;
  final String lastName;
  final String currentUserId;
  final String secondUserId;
  final String jwtToken; // Add jwtToken to the ProfilePage constructor

  const ProfilePage({
    Key? key,
    required this.profilePicture,
    required this.firstName,
    required this.lastName,
    required this.currentUserId,
    required this.secondUserId,
    required this.jwtToken, // Include jwtToken as required
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool creatingInbox = false;

  Future<void> sendFriendRequest() async {
    setState(() {
      creatingInbox = true; // Show the spinner while the request is being sent
    });

    final requestData = {
      'firstuserid': int.parse(widget.currentUserId),
      'seconduserid': int.parse(widget.secondUserId),
    };

    try {
      final response = await http.post(
        Uri.parse('https://datehubbackend.onrender.com/creatingnewconversation/startconva'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          creatingInbox = false;
        });
        final inbox = json.decode(response.body);
        if (inbox.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Chills(
                userId: widget.secondUserId,
                myUserId: widget.currentUserId,
                firstName: widget.firstName,
                lastName: widget.lastName,
                profilePicture: widget.profilePicture,
              ),
            ),
          );
        }
      } else {
        setState(() {
          creatingInbox = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send friend request')));
      }
    } catch (e) {
      setState(() {
        creatingInbox = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void openMessageScreen() {
    // Navigate to the message screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chills(  // Replace this with the correct message screen
          userId: widget.secondUserId,
          myUserId: widget.currentUserId,
          firstName: widget.firstName,
          lastName: widget.lastName,
          profilePicture: widget.profilePicture,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convert currentUserId and secondUserId from String to int
    int currentUserId = int.parse(widget.currentUserId);
    int secondUserId = int.parse(widget.secondUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.firstName} ${widget.lastName}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use Center widget to align profile photo in the middle of the horizontal axis
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(widget.profilePicture),
                  ),
                ),
                const SizedBox(height: 20),
                creatingInbox
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          // "Add Friend" Button with Gradient and Rounded Corners
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),  // Reduced horizontal padding
                            child: ElevatedButton(
                              onPressed: sendFriendRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, // Transparent background for gradient
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                elevation: 0, // No shadow
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue, Colors.blueAccent], // Gradient from blue to light blue
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Padding around the text
                                  child: const Text(
                                    'Add Friend',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 8),  // Reduced space between buttons
                          
                          // "Message" Button with Gradient and Rounded Corners
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),  // Reduced horizontal padding
                            child: ElevatedButton(
                              onPressed: openMessageScreen,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, // Transparent background for gradient
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                elevation: 0, // No shadow
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red, Colors.orange], // Gradient from red to orange
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Padding around the text
                                  child: const Text(
                                    'Message',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ProfilePostListPage(
              currentUserId: currentUserId, // Pass as int here
              currentEmail: widget.currentUserId, // You should pass an actual email, this can be updated accordingly
              secondUserId: secondUserId, // Pass as int here
              jwtToken: widget.jwtToken, // Pass jwtToken to ProfilePostListPage
            ),
          ),
        ],
      ),
    );
  }
}
