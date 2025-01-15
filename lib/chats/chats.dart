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
    chatRepository =
        ChatRepository(apiUrl: 'https://datehubbackend.onrender.com');
    chatService = ChatService(chatRepository: chatRepository);
    fetchUsers();
  }

  // Callback when a new message is received via SSE
  void _onNewMessageReceived(Map<String, dynamic> message) {
    setState(() {
      final inboxId = message['inboxid']?.toString();
      if (inboxId != null) {
        users = users.map((user) {
          if (user['inboxData']?['inboxid']?.toString() == inboxId) {
            user['lastMessage'] = message['message'];
            user['lastMessageTime'] = message['createdat'];
          }
          return user;
        }).toList();

        // Sort users by last message time (newest first)
        users.sort((a, b) {
          final timeA =
              DateTime.tryParse(a['lastMessageTime'] ?? '') ?? DateTime(1970);
          final timeB =
              DateTime.tryParse(b['lastMessageTime'] ?? '') ?? DateTime(1970);

          // Debug print to show the parsed times
          //print("Comparing timeA: $timeA with timeB: $timeB");

          return timeB.compareTo(timeA); // Sorting in descending order
        });

        // Debugging print for users list after sorting
        //print("Users list after sorting: ${users.map((user) => user['lastMessageTime']).toList()}");
      }
    });
  }

  // Fetch users and their last message timestamps
  void fetchUsers() async {
    try {
      final usersData = await chatService.getUsers(widget.myUserId);
      //print("Fetched users: $usersData"); // Debugging print

      // Fetch the last message for each user and set the timestamp
      for (var user in usersData) {
        final inboxId = user['inboxData']?['inboxid']?.toString() ?? '';
        final lastMessage = await chatService.getLastMessage(inboxId);
        final createdAt = lastMessage['createdat'] ?? '';
        user['lastMessage'] = lastMessage['message'];
        user['lastMessageTime'] = createdAt;

        // Debugging print for each user
        //print("User ${user['firstname']} ${user['lastname']}: lastMessage=${user['lastMessage']} at $createdAt");
      }

      setState(() {
        users = usersData;
        // Sort users based on the last message time (newest first)
        users.sort((a, b) {
          final timeA =
              DateTime.tryParse(a['lastMessageTime'] ?? '') ?? DateTime(1970);
          final timeB =
              DateTime.tryParse(b['lastMessageTime'] ?? '') ?? DateTime(1970);

          // Debug print to show the parsed times
          //print("Comparing timeA: $timeA with timeB: $timeB");

          return timeB.compareTo(timeA); // Sorting in descending order
        });

        // Debugging print for users list after sorting
        //print("Users list after sorting: ${users.map((user) => user['lastMessageTime']).toList()}");

        loading = false;
        error = '';
      });

      List<String> activeInboxIds = usersData
          .map((user) => user['inboxData']?['inboxid']?.toString() ?? '')
          .where((inboxId) => inboxId.isNotEmpty)
          .toList();

      // Start SSE listener
      chatRepository.listenToSse(
        activeInboxIds,
        widget.myUserId,
        (Map<String, dynamic> message) {
          _onNewMessageReceived(message);
        },
      );

      chatRepository.listenToStatusSse(
        activeInboxIds,
        widget.myUserId,
      );

      chatRepository.listenToPostSse(
        activeInboxIds,
        widget.myUserId,
        (Map<String, dynamic> message) {
          _onNewMessageReceived(message);
        },
      );
    } catch (e) {
      setState(() {
        error = 'Failed to load users';
        loading = false;
      });
    }
  }

  // Navigate to chat inbox for a user
  Future<void> navigateToInbox(int userId, String firstName, String lastName,
      String profilePicture, String inboxId) async {
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

  // Get the last message for a user
  Future<Map<String, dynamic>> getLastMessageForUser(String inboxId) async {
    try {
      final lastMessage = await chatService.getLastMessage(inboxId);
      final message = lastMessage['message'] ?? '';
      final createdAt = lastMessage['createdat'] ?? '';
      final lastMessageStatusv = lastMessage['status'];
      final messageId = lastMessage['id']; // This is your message ID
      final sender = lastMessage['userid'];

      //print("Message ID: $messageId");

      return {
        'message': message,
        'createdAt': createdAt,
        'lastMessageStatus': lastMessageStatusv,
        'messageId': messageId, // Make sure to include the message ID here
        'sender': sender,
      };
    } catch (e) {
      return {
        'message': 'Unable to fetch message',
        'createdAt': '',
        'messageId': ''
      };
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
                        String inboxId =
                            user['inboxData']?['inboxid']?.toString() ?? '';

                        return UserListItem(
                          firstName: firstName,
                          lastName: lastName,
                          profilePicture: profilePicture,
                          inboxId: inboxId,
                          lastMessageFuture: getLastMessageForUser(inboxId),
                          onTap: () async {
                            // Fetch message ID and status before navigating
                            final lastMessage =
                                await getLastMessageForUser(inboxId);
                            final messageId = lastMessage['messageId'];
                            final newStatus =
                                'seen'; // Update this based on your logic
                            final sender = lastMessage['sender'];
                            final oldStatus = lastMessage['lastMessageStatus'];

                            // Navigate to inbox
                            navigateToInbox(
                              user['userid'],
                              firstName,
                              lastName,
                              profilePicture,
                              inboxId,
                            );

                            // Update message status to seen
                            if (messageId != null &&
                                sender.toString() != widget.myUserId &&
                                oldStatus == 'received') {
                              //print("match kkkkkkkkkkkkkkkkkkkkkkkkkkkkkk");
                              chatRepository.updateMessageStatusToSeen(
                                messageId.toString(),
                                newStatus,
                              );
                              print(
                                  "updating message to seen, message id $messageId, ${widget.myUserId}");
                            } else {
                              print("not updating message to seen");
                            }
                          },
                          myUserId: widget.myUserId,
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
                                                                  
                                                                                                                                                          
                                                                                                                                                                            
                            
                                               
                                                                  
                
                              