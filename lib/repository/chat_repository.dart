import 'dart:convert';
import 'package:http/http.dart' as http;
import '/localDataBase/local_database.dart'; // Import the LocalDatabase class

class ChatRepository {
  final String apiUrl;
  // Cache for the last message for each inbox
  Map<String, Map<String, dynamic>> _lastMessageCache = {};

  ChatRepository({required this.apiUrl});

  // Fetch inbox data for a user
  Future<Map<String, dynamic>> fetchInboxData(String userId, String myUserId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/inboxparticipants/currentinbox/$userId/$myUserId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {'inboxid': data['inboxid']};
        } else {
          throw Exception('No inbox data found');
        }
      } else {
        throw Exception('Failed to load inbox data');
      }
    } catch (e) {
      throw Exception('Error fetching inbox: $e');
    }
  }

  // Fetch messages, prioritizing local storage
  Future<List<dynamic>> fetchMessages(String inboxId) async {
    try {
      // First, check local database for messages
      List<Map<String, dynamic>> localMessages = await LocalDatabase.getMessages(inboxId);

      // If messages exist in local storage, return them
      if (localMessages.isNotEmpty) {
        return localMessages;
      }

      // If no messages in local storage, fetch from server
      final response = await http.get(Uri.parse('$apiUrl/message/$inboxId/messageS'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data.isNotEmpty ? data : [];
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print("Error fetching messages: $e");
      throw Exception('Error fetching messages: $e');
    }
  }

  // Fetch the last message from either local storage or server
  Future<Map<String, dynamic>> getLastMessage(String inboxId) async {
    // Check if the last message is already in cache
    if (_lastMessageCache.containsKey(inboxId)) {
      return _lastMessageCache[inboxId]!;
    }

    // Check local database for the last message
    final lastMessage = await LocalDatabase.getLastMessage(inboxId);
    if (lastMessage != null) {
      _updateLastMessageCache(inboxId, lastMessage);
      return lastMessage;
    }

    // Fetch all messages from the server
    final messages = await fetchMessages(inboxId);
    if (messages.isNotEmpty) {
      _updateLastMessageCache(inboxId, messages.last);
      return messages.last;
    }

    // Return an empty map if no messages exist
    return {};
  }

  // Save the last message to the cache
  void _updateLastMessageCache(String inboxId, Map<String, dynamic> message) {
    _lastMessageCache[inboxId] = message;
  }

  // Send a new message
  Future<void> sendMessage(String inboxId, String userId, String messageText) async {
    try {
      final requestData = {
        'inboxid': inboxId,
        'userid': userId,
        'message': messageText,
      };

      final response = await http
          .post(
            Uri.parse('$apiUrl/message/send'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // If the message is sent successfully to the server, store it locally
        await LocalDatabase.saveMessage(inboxId, userId, messageText);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Fetch users from the API
  Future<List<dynamic>> fetchUsers(String userId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/inboxparticipants/$userId/chat'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Save received message to the local database
  Future<void> saveReceivedMessage(String inboxId, Map<String, dynamic> message) async {
    try {
      // Save the message to the local database
      await LocalDatabase.saveMessage(inboxId, message['userid'], message['message']);
    } catch (e) {
      print("Error saving received message: $e");
    }
  }

  // Handle incoming messages from SSE
  void handleSseMessage(Map<String, dynamic> message, List<String> activeInboxIds) {
    try {
      String inboxId = message['inboxid'].toString();

      // Debugging: Log the incoming message
      print("SSE Message Received: $message");

      // Check if the message belongs to any of the active inboxes
      if (activeInboxIds.contains(inboxId)) {
        // Debugging: Log if message matches active inbox
        print("Message belongs to an active inbox: $inboxId");
        // Save the incoming message to local storage
        saveReceivedMessage(inboxId, message);
      } else {
        print('Message does not belong to any of the active inboxes: $inboxId');
      }
    } catch (e) {
      print("Error handling SSE message: $e");
    }
  }

  // Function to listen to SSE (Server-Sent Events) and save new messages to the local database
  Future<void> listenToSse(List<String> activeInboxIds) async {
    try {
      final uri = Uri.parse('$apiUrl/message/events');
      print("Initiating SSE connection to: $uri"); // Debugging line

      final client = http.Client();
      final request = http.Request('GET', uri);

      final streamedResponse = await client.send(request);

      // Check if the connection was successful
      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        print("SSE connection established successfully.");
        final eventStream = streamedResponse.stream;

        await for (var chunk in eventStream) {
          String chunkString = utf8.decode(chunk);
          print("Received chunk: $chunkString"); // Debugging line

          List<String> events = chunkString.split('\n');
          for (var event in events) {
            if (event.isNotEmpty) {
              try {
                final message = json.decode(event);
                print("Processing event: $message"); // Debugging line
                handleSseMessage(message, activeInboxIds);
              } catch (e) {
                print("Error decoding event: $e");
              }
            }
          }
        }
      } else {
        print("Error in SSE connection. Status code: ${streamedResponse.statusCode}");
      }
    } catch (e) {
      print("Error listening to SSE: $e");
    }
  }
}
