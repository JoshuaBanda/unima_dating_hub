import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/services/chat_service.dart'; // Import ChatService
import '/repository/chat_repository.dart'; // Import ChatRepository
import '/chats/full_screen_image_page.dart';
import 'inbox_messages.dart';
import '/chats/contacts_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class Chats extends StatefulWidget {
  final String myUserId; // The ID of the logged-in user

  const Chats({super.key, required this.myUserId});

  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  late final ChatService chatService; // Declare ChatService
  List<dynamic> users = [];
  bool loading = true;
  String error = '';
  bool creatingInbox = false;
  double _imageSize = 30.0; // Initial image size for the CircleAvatar

  // Fetch users using the ChatService
  Future<void> fetchUsers() async {
    try {
      final usersData = await chatService.getUsers(widget.myUserId);
      setState(() {
        users = usersData;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'No users available';
        loading = false;
      });
    }
  }

  // Create inbox conversation and navigate to the chat page
  Future<void> navigateToInbox(int userId, String firstName, String lastName, String profilePicture) async {
    setState(() {
      creatingInbox = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chills(
          userId: userId.toString(),
          myUserId: widget.myUserId, // Pass the logged-in user's ID
          firstName: firstName, // Pass the user's first name
          lastName: lastName, // Pass the user's last name
          profilePicture: profilePicture, // Pass the profile picture
        ),
      ),
    );
  }

  // Function to toggle image size when tapped
  void _toggleImageSize() {
    setState(() {
      _imageSize = _imageSize == 30.0 ? 50.0 : 30.0; // Toggle between two sizes
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize the service with the repository
    chatService = ChatService(chatRepository: ChatRepository(apiUrl: 'https://datehubbackend.onrender.com'));
    fetchUsers(); // Fetch users on screen load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.dancingScript(
            textStyle: TextStyle(
              fontSize: 30,
              color: Colors.red,
              fontStyle: FontStyle.italic, // Slanted look
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: SpinKitFadingCircle(color: Colors.grey, size: 50.0))
          : error.isNotEmpty
              ? Center(child: Text(error))
              : users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        String profilepicture = user['profilepicture'] ?? ''; // Safely handle null profilePicture

                        return GestureDetector(
                          onTap: () => navigateToInbox(
                            user['userid'],              // Pass user ID
                            user['firstname'],           // Pass the user's first name
                            user['lastname'],            // Pass the user's last name
                            profilepicture,              // Pass the profile picture URL
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  // Navigate to the full-screen image view
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImage(
                                        imageUrl: profilepicture.isNotEmpty
                                            ? profilepicture
                                            : 'assets/default_profile.png', // Use default image if null
                                      ),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: _imageSize, // Dynamically change the size
                                  backgroundImage: profilepicture.isNotEmpty
                                      ? CachedNetworkImageProvider(profilepicture)
                                      : const AssetImage('assets/default_profile.png') as ImageProvider,
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
              builder: (context) => ContactsScreen(myUserId: widget.myUserId),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 255, 136, 0),
        child: const FaIcon(FontAwesomeIcons.users),
      ),
    );
  }
}
