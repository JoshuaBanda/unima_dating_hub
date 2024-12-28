import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For formatting the timestamp
import '/services/chat_service.dart';
import '/repository/chat_repository.dart';
import '/chats/full_screen_image_page.dart';
import '/chats/contacts_screen.dart';
import 'messages/chat_messages.dart';

class Chats extends StatefulWidget {
  final String myUserId;
  final String jwtToken;

  const Chats({super.key, required this.myUserId, required this.jwtToken});

  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  late final ChatService chatService;
  List<dynamic> users = [];
  bool loading = true;
  String error = '';
  bool creatingInbox = false;
  double _imageSize = 30.0;

  @override
  void initState() {
    super.initState();
    chatService = ChatService(chatRepository: ChatRepository(apiUrl: 'https://datehubbackend.onrender.com'));
    fetchUsers();
  }

  // Method to fetch users and their last message timestamps
  Future<void> fetchUsers() async {
    try {
      final usersData = await chatService.getUsers(widget.myUserId);
      // Include the timestamp of the last message to help with sorting
      for (var user in usersData) {
        final inboxId = user['inboxData']?['inboxid']?.toString() ?? '';
        final lastMessage = await chatService.getLastMessage(inboxId);
        final createdAt = lastMessage['createdAt'] ?? '';
        user['lastMessageTime'] = createdAt; // Add the timestamp for sorting
      }

      // Sort the users by the last message time (most recent first)
      usersData.sort((a, b) {
        final timeA = DateTime.tryParse(a['lastMessageTime'] ?? '') ?? DateTime(1970);
        final timeB = DateTime.tryParse(b['lastMessageTime'] ?? '') ?? DateTime(1970);
        return timeB.compareTo(timeA); // Sort in descending order
      });

      setState(() {
        users = usersData;
        loading = false;
        error = '';
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() {
        error = 'Failed to load users';
        loading = false;
      });
    }
  }

  // Format the timestamp to a 12-hour time format
  String formatTimestamp(String timestamp) {
    if (timestamp.isEmpty || timestamp == 'No timestamp available') {
      debugPrint("Timestamp is empty");
      return 'No timestamp available';
    }

    try {
      // Ensure the timestamp has 'T' separating date and time (if lowercase 't', replace with uppercase 'T')
      final String timestampLower = timestamp.toLowerCase(); // Convert to lowercase if needed
      final String correctedTimestamp = timestampLower.replaceAll('t', 'T'); // Fix lowercase 't'

      // Remove milliseconds from the timestamp if they are included (optional)
      final trimmedTimestamp = correctedTimestamp.split('.')[0];  // Keep only the date and time part


      final DateTime dateTime = DateTime.parse(trimmedTimestamp);

      // Extract and format the time into 12-hour format
      final DateFormat timeFormatter = DateFormat('hh:mm a'); // 12-hour format with AM/PM
      final String formattedTime = timeFormatter.format(dateTime);


      return formattedTime;
    } catch (e) {
      debugPrint('Error formatting timestamp: $e');
      return 'Invalid time format';
    }
  }

  // Method to fetch the last message for a user
  Future<Map<String, dynamic>> getLastMessageForUser(String inboxId) async {
    try {
      final lastMessage = await chatService.getLastMessage(inboxId);
      
      // Debugging the response to verify the structure

      // Ensure createdAt is present in the response
      final message = lastMessage['message'] ?? '';
      final createdAt = lastMessage['createdat'] ?? '';  // Make sure to handle createdAt as per the response key

      // Debugging to see the values of message and createdAt

      return {
        'message': message,
        'createdAt': createdAt,
      };
    } catch (e) {
      debugPrint('Error fetching last message: $e');
      return {'message': 'Unable to fetch message', 'createdAt': ''};
    }
  }

  // Navigate to the inbox of the selected user
  Future<void> navigateToInbox(int userId, String firstName, String lastName, String profilePicture, String inboxId) async {
    setState(() {
      creatingInbox = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chills(
          userId: userId.toString(),
          myUserId: widget.myUserId,
          firstName: firstName,
          lastName: lastName,
          profilePicture: profilePicture,
          inboxid: inboxId,
        ),
      ),
    );
  }

  // Handle message types (text, image, file)
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
    return Scaffold(
      body: loading
          ? const Center(
              child: SpinKitFadingCircle(
                color: Colors.grey,
                size: 50.0,
              ),
            )
          : error.isNotEmpty
              ? Center(
                  child: Text(error),
                )
              : users.isEmpty
                  ? const Center(
                      child: Text('No users found'),
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        String profilePicture = user['profilepicture'] ?? '';
                        String firstName = user['firstname'] ?? 'Unknown';
                        String lastName = user['lastname'] ?? 'User';
                        String inboxId = user['inboxData']?['inboxid']?.toString() ?? '';

                        return GestureDetector(
                          onTap: () => navigateToInbox(
                            user['userid'],
                            firstName,
                            lastName,
                            profilePicture,
                            inboxId,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                child: CircleAvatar(
                                  radius: _imageSize,
                                  backgroundImage: profilePicture.isNotEmpty
                                      ? CachedNetworkImageProvider(profilePicture)
                                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                                ),
                              ),
                              title: Text(
                                '$firstName $lastName',
                                style: GoogleFonts.montserrat(
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              subtitle: FutureBuilder<Map<String, dynamic>>(
                                future: getLastMessageForUser(inboxId),
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
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactsScreen(
                myUserId: widget.myUserId,
                jwtToken: widget.jwtToken,
              ),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(80, 255, 4, 4),
        child: const FaIcon(FontAwesomeIcons.users),
      ),
    );
  }
}
