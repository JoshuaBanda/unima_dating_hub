import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '/repository/chat_repository.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImageProvider
import 'package:audioplayers/audioplayers.dart';

class Chills extends StatefulWidget {
  final String userId;
  final String myUserId;
  final String firstName;
  final String lastName;
  final String profilePicture;
  final dynamic inboxid;

  const Chills({
    super.key,
    required this.userId,
    required this.myUserId,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.inboxid,
  });

  @override
  State<Chills> createState() => _ChillsState();
}

class _ChillsState extends State<Chills> {
  late ChatRepository chatRepository;
  late IO.Socket socket;

  late Future<Map<String, dynamic>> thisChatInboxFuture;
  late Future<List<dynamic>> messagesFuture;
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> currentMessages = [];
  bool isSending = false;
  String inboxId = "";
  final ScrollController _scrollController = ScrollController();
  final audioPlayer = AudioPlayer();

  // New variable to track message sending status
  Map<String, bool> sendingStatus = {};

  @override
  void initState() {
    super.initState();

    chatRepository =
        ChatRepository(apiUrl: 'https://datehubbackend.onrender.com');
    thisChatInboxFuture = _fetchCommonInboxData();

    socket = IO.io('https://datehubbackend.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.on('connect', (_) {
      print('Socket connected: ${socket.id}');
    });

    socket.on('disconnect', (_) {
      print('Socket disconnected');
    });

    socket.on('connect_error', (error) {
      print('Socket connection error: $error');
    });

    socket.on('refresh', (data) {
      print('Received refresh data: $data');
      setState(() {
        if (data['data']['inboxid'] == inboxId &&
            data['data']['userid'] != widget.myUserId) {
          print('Inserting message into currentMessages');
          currentMessages.add(data['data']); // Add new message at the bottom
          _sortMessagesByDate(); // Ensure messages are sorted after adding
          _scrollToBottom(); // Scroll to bottom after receiving new message

          _playNotificationSound('sounds/message_received.mp3');
        }
      });
    });
  }

  Future<void> _playNotificationSound(String soundPath) async {
    try {
      await audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchCommonInboxData() async {
    try {
      print('Fetching inbox data...');
      inboxId = widget.inboxid.toString();
      messagesFuture = chatRepository.fetchMessages(inboxId);
      print("message $messagesFuture");

      return {'inboxid': inboxId}; // Return a map with inboxId
    } catch (e) {
      print('Error fetching inbox data: $e');
      throw Exception('Error fetching inbox data: $e');
    }
  }

  Future<void> _sendMessage(String messageText) async {
    if (messageText.isEmpty || isSending) return;

    String messageId = DateTime.now().millisecondsSinceEpoch.toString(); // Unique message ID

    setState(() {
      isSending = true;
      final message = {
        'message': messageText,
        'createdat': DateTime.now().toString(),
        'userid': widget.myUserId,
        'messageId': messageId, // Add unique ID
        'status': 'sent'
      };
      currentMessages.add(message); // Add the new message at the bottom
      sendingStatus[messageId] = false; // Initially mark the message as not sent
    });

    try {
      print('Sending message: $messageText');
      await chatRepository.sendMessage(inboxId, widget.myUserId, messageText, 'sent');
      print('Message sent successfully');

      socket.emit('triggerRefresh', {
        'inboxid': inboxId,
        'userid': widget.myUserId,
        'message': messageText,
      });
      print('Sent triggerRefresh event to server');

      setState(() {
        sendingStatus[messageId] = true;
      });

      _playNotificationSound('sounds/message_sent.mp3');
    } catch (error) {
      print('Error sending message: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      setState(() {
        isSending = false;
      });
      _messageController.clear(); // Clear the message text field
      _scrollToBottom(); // Ensure the view scrolls to the bottom after sending
    }
  }

  void _sortMessagesByDate() {
    currentMessages.sort((a, b) {
      DateTime dateA = DateTime.parse(a['createdat']);
      DateTime dateB = DateTime.parse(b['createdat']);
      return dateA.compareTo(dateB); // Sorting in ascending order
    });
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent); // Scroll to the bottom of the list
      }
    });
  }

  String _formatTime(String dateString) {
    if (dateString.isEmpty) return ''; // Avoid null or empty date errors
    final date = DateTime.parse(dateString);
    return DateFormat('hh:mm a').format(date); // Format to '12:30 PM'
  }

  Map<String, List<dynamic>> _groupMessagesByDate(List<dynamic> messages) {
    Map<String, List<dynamic>> groupedMessages = {};

    for (var message in messages) {
      DateTime messageDate = DateTime.parse(message['createdat']);
      String formattedDate = DateFormat('yyyy-MM-dd').format(messageDate);

      if (groupedMessages.containsKey(formattedDate)) {
        groupedMessages[formattedDate]!.add(message);
      } else {
        groupedMessages[formattedDate] = [message];
      }
    }

    return groupedMessages;
  }

  @override
  void dispose() {
    print('Disconnecting and disposing WebSocket...');
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  // Double-tap detection for edit and delete actions
  void _onMessageDoubleTap(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
  title: Text(
    'Message Options',
    style: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  ),
  content: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _editMessage(message);
          },
          icon: Icon(
            Icons.edit,
            color: Colors.blue,
          ),
          label: Text(
            'Edit',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Divider(), // Divider to separate options
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _deleteMessage(message);
          },
          icon: Icon(
            Icons.delete,
            color: Colors.red,
          ),
          label: Text(
            'Delete',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15.0),
  ),
  elevation: 5.0,
),
    );
  }

  // Method to edit the message
  void _editMessage(Map<String, dynamic> message) {
    _messageController.text = message['message'] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
  title: Text(
    'Edit Message',
    style: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  ),
  content: Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextField(
      controller: _messageController,
      decoration: InputDecoration(
        hintText: 'Edit your message...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      style: TextStyle(fontSize: 16.0, color: Colors.black),
    ),
  ),
  actions: [
    TextButton(
      onPressed: () {
        Navigator.pop(context);
        String newMessage = _messageController.text;
        if (newMessage.isNotEmpty) {
          _updateMessage(message, newMessage);
        }
      },
      child: Text(
        'Save',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15.0),
  ),
  elevation: 5.0,
)

    );
  }

  // Update the message locally and remotely
  Future<void> _updateMessage(Map<String, dynamic> message, String newMessage) async {
    setState(() {
      message['message'] = newMessage;
    });

    try {
      await chatRepository.updateMessage(message['messageId'], newMessage);
      socket.emit('triggerRefresh', {'inboxid': inboxId, 'userid': widget.myUserId, 'message': newMessage});
    } catch (error) {
      print('Error updating message: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating message')));
    }
  }

  // Delete the message locally and remotely
  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    setState(() {
      currentMessages.remove(message); // Remove from local list
    });

    try {
      await chatRepository.deleteMessage(inboxId, message['messageId']);
      socket.emit('triggerRefresh', {'inboxid': inboxId, 'userid': widget.myUserId, 'message': 'Message Deleted'});
    } catch (error) {
      print('Error deleting message: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting message')));
    }
  }

  // Build message widget with double-tap functionality for edit and delete
  Widget _buildMessageWidget(Map<String, dynamic> message) {
    final messageText = message['message'] ?? 'No content';
    final timestamp = message['createdat'] ?? '';
    final isCurrentUser = message['userid'].toString() == widget.myUserId;
    String messageId = message['messageId'] ?? '';
    bool isSent = sendingStatus[messageId] ?? false;

    return GestureDetector(
      onDoubleTap: () => _onMessageDoubleTap(message), // Double tap to show options
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment:
                isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.5,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  gradient: isCurrentUser
                      ? LinearGradient(
                          colors: [Colors.pink, Colors.red],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isCurrentUser ? null : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      messageText,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.check,
                          color: isSent
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : Colors.transparent,
                          size: 16.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(
                            color: isCurrentUser ? Colors.white : Colors.grey,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.firstName} ${widget.lastName}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          CircleAvatar(
            radius: 20, // Adjust the radius as needed
            backgroundImage: widget.profilePicture.isNotEmpty
                ? CachedNetworkImageProvider(widget.profilePicture)
                : const AssetImage('assets/default_profile.png')
                    as ImageProvider,
          ),
          SizedBox(width: 10),
        ],
        backgroundColor: Colors.white, // Set the background color to white
        elevation: 5, // Adds a shadow effect under the AppBar
        shape: Border(
          bottom: BorderSide(
              color: Colors.black, width: 2), // Black border at the bottom
        ),
        toolbarHeight: 80, // Increase AppBar height to make it more prominent
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: thisChatInboxFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitFadingCircle(color: Colors.grey, size: 50.0),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No inbox data found.'));
          } else {
            final inboxData = snapshot.data!; 
            inboxId = inboxData['inboxid'].toString();

            return FutureBuilder<List<dynamic>>(
              future: messagesFuture,
              builder: (context, messageSnapshot) {
                if (messageSnapshot.connectionState == ConnectionState.waiting && currentMessages.isEmpty) {
                  return const Center(
                    child: SpinKitFadingCircle(color: Colors.grey, size: 50.0),
                  );
                } else if (messageSnapshot.hasError) {
                  return Center(child: Text('Error: ${messageSnapshot.error}'));
                } else {
                  if (currentMessages.isEmpty) {
                    currentMessages = messageSnapshot.data ?? [];
                    _sortMessagesByDate(); // Sort messages on initial load
                    _scrollToBottom(); // Scroll to bottom initially
                  }

                  Map<String, List<dynamic>> groupedMessages = _groupMessagesByDate(currentMessages);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          controller: _scrollController,
                          children: groupedMessages.entries.map((entry) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey),
                                  ),
                                ),
                                ...entry.value.map((message) => _buildMessageWidget(message)).toList(),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _sendMessage(_messageController.text);
                              },
                              icon: const Icon(Icons.send),
                              color: Colors.pink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
