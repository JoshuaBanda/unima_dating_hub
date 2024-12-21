import 'package:flutter/material.dart';
import 'inbox_messages.dart';  // Assuming this imports the Chills screen

class ChatItem extends StatelessWidget {
  final String userId;
  final String chatName;
  final String myUserId; // Adding myUserId for passing to UserProfilePage
  final String firstName; // Adding firstName
  final String lastName; // Adding lastName
  final String profilePicture; // Add profilePicture

  const ChatItem({
    super.key,
    required this.userId,
    required this.chatName,
    required this.myUserId,
    required this.firstName,  // Adding firstName
    required this.lastName,   // Adding lastName
    required this.profilePicture, // Add profilePicture
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: ListTile(
        title: Text(
          chatName, 
          style: TextStyle(color: Colors.grey.shade600),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Chills(
                userId: userId,        // Passing userId
                myUserId: myUserId,    // Passing myUserId
                firstName: firstName,   // Passing firstName
                lastName: lastName,     // Passing lastName
                profilePicture: profilePicture, // Passing profilePicture
              ),
            ),
          );
        },
      ),
    );
  }
}