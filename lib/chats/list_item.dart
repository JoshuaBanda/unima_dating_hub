import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '/chats/full_screen_image_page.dart';
import 'package:intl/intl.dart';  // Add this import


class UserListItem extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String profilePicture;
  final String inboxId;
  final Future<Map<String, dynamic>> lastMessageFuture;
  final VoidCallback onTap;

  const UserListItem({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.inboxId,
    required this.lastMessageFuture,
    required this.onTap,
  }) : super(key: key);

  // Format timestamp to 12-hour time format
  String formatTimestamp(String timestamp) {
    if (timestamp.isEmpty || timestamp == 'No timestamp available') {
      return 'No timestamp available';
    }

    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final formattedTime = DateFormat('hh:mm a').format(dateTime);
      return formattedTime;
    } catch (e) {
      return 'Invalid time format';
    }
  }

  // Check if the provided string is a valid URL
  bool isValidUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    return uri != null && uri.hasAbsolutePath && (uri.isScheme('http') || uri.isScheme('https'));
  }

  // Determine message type icon (text, image, or file)
  Widget _getMessageIcon(String message) {
    if (message.contains('image')) {
      return Icon(Icons.image, color: Colors.blue);
    } else if (message.contains('file')) {
      return Icon(Icons.attach_file, color: Colors.green);
    } else {
      return Icon(Icons.textsms, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: GestureDetector(
            onTap: () {
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
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
              // Optional: Add loading placeholder
              onBackgroundImageError: (exception, stackTrace) {
                print("Error loading profile picture: $exception");
              },
            ),
          ),
          title: Text(
            '$firstName $lastName',
            style: GoogleFonts.montserrat(
              textStyle: TextStyle(fontSize: 18),
            ),
          ),
          subtitle: FutureBuilder<Map<String, dynamic>>(
            future: lastMessageFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  children: [
                    const SpinKitCircle(color: Colors.grey),
                    const SizedBox(width: 10),
                    const Text('Loading...'),
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!['message'].isEmpty) {
                return const Text('No messages yet');
              } else {
                final lastMessage = snapshot.data!['message'];
                final timestamp = snapshot.data!['createdAt'];
                final formattedTime = formatTimestamp(timestamp);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getMessageIcon(lastMessage),
                        const SizedBox(width: 10),
                        Text(lastMessage),
                      ],
                    ),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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
