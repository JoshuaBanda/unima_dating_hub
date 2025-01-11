import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/services/chat_service.dart';
import '/repository/chat_repository.dart';
import 'messages/chat_messages.dart';
import '/chats/contacts_screen.dart';
import 'list_item.dart';

class Chats extends StatefulWidget {
  final String myUserId;
  final String jwtToken;

  const Chats({super.key, required this.myUserId, required this.jwtToken});

  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  late final ChatService chatService;
  late final ChatRepository chatRepository;
  List<dynamic> users = [];
  bool loading = true;
  String error = '';
  bool creatingInbox = false;

  @override
  void initState() {
    super.initState();
    //print('Initializing Chats...');
    chatRepository = ChatRepository(apiUrl: 'https://datehubbackend.onrender.com');
    chatService = ChatService(chatRepository: chatRepository);
    fetchUsers();
  }

  // Callback for SSE messages
// Callback for SSE messages
// Callback for SSE messages
void _onNewMessageReceived(Map<String, dynamic> message) {
  setState(() {
    final inboxId = message['inboxid']?.toString();
    if (inboxId != null) {
      // Create a new users list with updated data
      users = users.map((user) {
        if (user['inboxData']?['inboxid']?.toString() == inboxId) {
          // Update the last message and timestamp for the correct user
          user['lastMessage'] = message['message'];
          user['lastMessageTime'] = message['createdAt'];
        }
        return user;
      }).toList(); // Ensure this creates a new list

      // Sort the users based on the last message time (descending)
      users.sort((a, b) {
        final timeA = DateTime.tryParse(a['lastMessageTime'] ?? '') ?? DateTime(1970);
        final timeB = DateTime.tryParse(b['lastMessageTime'] ?? '') ?? DateTime(1970);
        return timeB.compareTo(timeA); // Sorting in descending order
      });
    }
  });
}

  // Fetch users and their last message timestamps
void fetchUsers() async {
  try {
    final usersData = await chatService.getUsers(widget.myUserId);

    // Create a ValueNotifier for each user
    for (var user in usersData) {
      final inboxId = user['inboxData']?['inboxid']?.toString() ?? '';
      final lastMessage = await chatService.getLastMessage(inboxId);
      final createdAt = lastMessage['createdAt'] ?? '';
      
      user['lastMessageNotifier'] = ValueNotifier<Map<String, dynamic>>({
        'message': lastMessage['message'],
        'createdAt': createdAt,
      });
    }

    setState(() {
      users = usersData;
      loading = false;
      error = '';
    });

    // Start the SSE listener
    List<String> activeInboxIds = usersData
        .map((user) => user['inboxData']?['inboxid']?.toString() ?? '')
        .where((inboxId) => inboxId.isNotEmpty)
        .toList();

    chatRepository.listenToSse(
      activeInboxIds,
      widget.myUserId,
      (Map<String, dynamic> message) {
        _onNewMessageReceived(message); // Update notifier
      },
    );

    chatRepository.listenToPostSse(
      activeInboxIds,
      widget.myUserId,
      (Map<String, dynamic> message) {
        _onNewMessageReceived(message); // Update notifier
      },
    );
  } catch (e) {
    setState(() {
      error = 'Failed to load users';
      loading = false;
    });
  }
}


  // Navigate to the chat inbox for a user
  Future<void> navigateToInbox(int userId, String firstName, String lastName, String profilePicture, String inboxId) async {
    //print('Navigating to inbox for user: $firstName $lastName');
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

  // Method to get the last message for a user
  Future<Map<String, dynamic>> getLastMessageForUser(String inboxId) async {
    try {
      //print('Fetching last message for inboxId: $inboxId');
      final lastMessage = await chatService.getLastMessage(inboxId);
      final message = lastMessage['message'] ?? '';
      final createdAt = lastMessage['createdat'] ?? '';
     // print('Last message for inboxId $inboxId: $message at $createdAt');
      return {
        'message': message,
        'createdAt': createdAt,
      };
    } catch (e) {
      //print('Error fetching last message for inboxId $inboxId: $e');
      return {'message': 'Unable to fetch message', 'createdAt': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    //print('Building Chats screen...');
    return Scaffold(
      body: loading
          ? const Center(
              child: SpinKitFadingCircle(
                color: Colors.grey,
                size: 50.0,
              ),
            )
          : error.isNotEmpty
              ? Center(child: Text(error))
              : users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        String profilePicture = user['profilepicture'] ?? '';
                        String firstName = user['firstname'] ?? 'Unknown';
                        String lastName = user['lastname'] ?? 'User';
                        String inboxId = user['inboxData']?['inboxid']?.toString() ?? '';

                        //print('Rendering user: $firstName $lastName');
                        return UserListItem(
                          firstName: firstName,
                          lastName: lastName,
                          profilePicture: profilePicture,
                          inboxId: inboxId,
                          lastMessageFuture: getLastMessageForUser(inboxId),
                          onTap: () => navigateToInbox(  // Correctly call navigateToInbox here
                            user['userid'],
                            firstName,
                            lastName,
                            profilePicture,
                            inboxId,
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //print('Navigating to Contacts screen...');
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
