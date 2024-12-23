import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:unima_dating_hub/posts/profile_post_list_page.dart'; // Import your ProfilePostListPage widget
import 'messages/contact_message.dart';

class ProfilePage extends StatefulWidget {
  final String profilePicture;
  final String firstName;
  final String lastName;
  final String currentUserId;
  final String secondUserId;
  final String jwtToken;

  const ProfilePage({
    Key? key,
    required this.profilePicture,
    required this.firstName,
    required this.lastName,
    required this.currentUserId,
    required this.secondUserId,
    required this.jwtToken,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool creatingInbox = false;

  Future<void> sendFriendRequest() async {
    setState(() {
      creatingInbox = true;
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
              builder: (context) => ContactMessage(
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactMessage(
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
    int currentUserId = int.parse(widget.currentUserId);
    int secondUserId = int.parse(widget.secondUserId);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
            child: Column(
              children: [
                Center(
                  child: Text(
                    '${widget.firstName} ${widget.lastName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGradientButton(
                            text: 'Add Friend',
                            colors: [Colors.blue, Colors.blueAccent],
                            onPressed: sendFriendRequest,
                          ),
                          const SizedBox(width: 16),
                          _buildGradientButton(
                            text: 'Message',
                            colors: [Colors.pink, Colors.red],
                            onPressed: openMessageScreen,
                          ),
                        ],
                      ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ProfilePostListPage(
              currentUserId: currentUserId,
              currentEmail: widget.currentUserId, // Update if email is required here
              secondUserId: secondUserId,
              jwtToken: widget.jwtToken,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
