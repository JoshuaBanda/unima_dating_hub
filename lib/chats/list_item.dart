import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '/chats/full_screen_image_page.dart';
import 'package:intl/intl.dart';

class UserListItem extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String profilePicture;
  final String inboxId;
  final Future<Map<String, dynamic>> lastMessageFuture;
  final VoidCallback onTap;
  final String myUserId;

  const UserListItem({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.inboxId,
    required this.lastMessageFuture,
    required this.onTap,
    required this.myUserId,
  }) : super(key: key);

  // Format timestamp to 12-hour time format
  String formatTimestamp(String timestamp) {
    if (timestamp.isEmpty || timestamp == 'No timestamp available') {
      //print("Invalid timestamp: $timestamp");
      return '';
    }

    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final formattedTime = DateFormat('hh:mm a').format(dateTime);
      //print("Formatted time: $formattedTime");
      return formattedTime;
    } catch (e) {
      //print("Error formatting timestamp: $e");
      return 'Invalid time format';
    }
  }

  // Check if the provided string is a valid URL
  bool isValidUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    bool isValid = uri != null &&
        uri.hasAbsolutePath &&
        (uri.isScheme('http') || uri.isScheme('https'));
    //print("Valid URL check for $url: $isValid");
    return isValid;
  }

  // Render status dot based on message status (sent or received)
  Widget _getStatusDot(String status) {
    Color dotColor;
    if (status == 'sent') {
      dotColor = Colors.grey;
      return Container(
        width: 8.0,
        height: 8.0,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      ); // Grey dot for sent
    } else if (status == 'received') {
      dotColor = Colors.grey; // Green dot for received
    } else if (status == 'seen') {
      dotColor = Colors.blue;
    } else {
      dotColor = Colors.grey; // Default to grey if status is unknown

      return Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ));
    }
    return Row(
      mainAxisSize: MainAxisSize.min, // Ensure the row takes the minimum space
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4.0), // Optional: Adds space between the dots
        Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        //print("User list item tapped for inboxId: $inboxId");
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: GestureDetector(
            onTap: () {
              //print("Profile picture tapped for $firstName $lastName");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(
                    imageUrl: isValidUrl(profilePicture)
                        ? profilePicture
                        : 'assets/default_profile.png',
                  ),
                ),
              );
            },
            child: CircleAvatar(
              radius: 30.0,
              backgroundImage: isValidUrl(profilePicture)
                  ? CachedNetworkImageProvider(profilePicture)
                  : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
              onBackgroundImageError: (exception, stackTrace) {
                //print("Error loading profile picture: $exception");
              },
            ),
          ),
          title: Text(
            '$firstName $lastName',
            style: GoogleFonts.montserrat(textStyle: TextStyle(fontSize: 18)),
          ),
          subtitle: FutureBuilder<Map<String, dynamic>>(
            future: lastMessageFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                //print("Loading message for inboxId: $inboxId");
                return Row(
                  children: [
                    const SpinKitCircle(color: Colors.grey, size: 20.0),
                    const SizedBox(width: 10),
                    const Text('Loading...'),
                  ],
                );
              } else if (snapshot.hasError) {
                print(
                    "Error loading last message for inboxId: $inboxId - ${snapshot.error}");
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData ||
                  snapshot.data!['message'] == null) {
                //print("No message available for inboxId: $inboxId");
                return const Text('');
              } else {
                final lastMessage = snapshot.data!['message'];
                final createdAt = snapshot.data!['createdAt'];
                final formattedTime = formatTimestamp(createdAt);
                final status = snapshot.data!['lastMessageStatus'] ??
                    'unknown'; // Get the status
                final sender = snapshot.data!['sender'];
                //print('hahahahahahahahahahahahahahahahahahahahahahahahahahahahahahahahahah$sender');
                //print("$status");
                // Debug the status value before using it
                //print("Status for inboxId: $inboxId is: $status");
                return Row(
                  children: [
                    Text(
                      lastMessage,
                      style: TextStyle(color: Colors.black87),
                    ),
                    if (sender.toString() == myUserId) ...[
                      const SizedBox(width: 10),
                      _getStatusDot(
                          status), // Function to return the status dot
                      const Spacer(), // Optional: Adds spacing at the end of the row
                    ],
                    Text(
                      formattedTime,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
