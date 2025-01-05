import 'dart:convert';
import 'package:http/http.dart' as http;
import '/localDataBase/local_database.dart'; // Import the LocalDatabase class
import 'package:unima_dating_hub/notifications/notification_service.dart';

class ChatRepository {
  final String apiUrl;
  Map<String, Map<String, dynamic>> _lastMessageCache = {};

  // Constructor
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
    if (_lastMessageCache.containsKey(inboxId)) {
      return _lastMessageCache[inboxId]!;
    }

    // Check local database for the last message
    final lastMessage = await LocalDatabase.getLastMessage(inboxId);
    if (lastMessage != null) {
      _updateLastMessageCache(inboxId, lastMessage);
      return lastMessage;
    }

    // Fetch messages from server
    final messages = await fetchMessages(inboxId);
    if (messages.isNotEmpty) {
      _updateLastMessageCache(inboxId, messages.last);
      return messages.last;
    }

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
    // Ensure inboxId and userId are converted to strings if they're integers
    String inboxIdStr = inboxId.toString();
    String userIdStr = message['userid'].toString();  // Convert userid to string
    String messageText = message['message'] ?? '';  // Safeguard in case 'message' is null

    await LocalDatabase.saveMessage(inboxIdStr, userIdStr, messageText);
  } catch (e) {
    print("Error saving received message: $e");
  }
}

// Handle incoming messages from SSE
void handleSseMessage(Map<String, dynamic> message, List<String> activeInboxIds, String currentUserId) async {
  try {
    String inboxId = message['inboxid'].toString();

    // Log incoming message for debugging
    print("SSE Message Received: $message");

    // Check if the message belongs to any of the active inboxes
    if (activeInboxIds.contains(inboxId)) {
      print("Message belongs to an active inbox: $inboxId");

      // If the message is from the current user, don't save it
      if (message['userid'] == currentUserId) {
        print("Message is from the current user, not saving it again.");
        return;
      }

      // Check if the message exists in local storage
      bool messageExists = await _checkMessageExists(inboxId, message);

      if (!messageExists) {
        // Save the message to the local database if it doesn't already exist
        await saveReceivedMessage(inboxId, message);

        // Display the notification since it's a new message
        NotificationService.showNotification(
          'New Message',
          message['message'] ?? 'No message content',
        );
      } else {
        print("Message already exists in local storage, not saving.");
      }
    } else {
      print("Message does not belong to any active inbox: $inboxId");
    }
  } catch (e) {
    print("Error handling SSE message: $e");
  }
}

// Check if the message already exists in local storage
Future<bool> _checkMessageExists(String inboxId, Map<String, dynamic> message) async {
  try {
    // Retrieve messages from local storage for the given inboxId
    List<Map<String, dynamic>> localMessages = await LocalDatabase.getMessages(inboxId);

    // Check if any message with the same content and timestamp already exists
    for (var storedMessage in localMessages) {
      // Compare the message content, user ID, and the created timestamp
      if (storedMessage['message'] == message['message'] &&
          storedMessage['userid'] == message['userid'] &&
          storedMessage['createdat'] == message['createdat']) {
        return true; // Message exists in local storage
      }
    }
    return false; // Message does not exist
  } catch (e) {
    print("Error checking if message exists: $e");
    return false; // Return false if there is an error, meaning the message is not found
  }
}

  // Listen to SSE (Server-Sent Events) and save new messages to the local database
Future<void> listenToSse(List<String> activeInboxIds, String currentUserId) async {
  try {
    final uri = Uri.parse('$apiUrl/message/event');
    print("Initiating SSE connection to: $uri");

    final client = http.Client();
    final request = http.Request('GET', uri);
    request.headers.addAll({
      'Accept': 'text/event-stream',
    });

    final streamedResponse = await client.send(request);

    if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
      print("SSE connection established successfully.");
      final eventStream = streamedResponse.stream;

      await for (var chunk in eventStream) {
        String chunkString = utf8.decode(chunk);
        print("Received chunk: $chunkString");

        // Split the chunk into individual events (lines separated by newlines)
        List<String> events = chunkString.split('\n');
        for (var event in events) {
          if (event.isNotEmpty) {
            try {
              // Extract the actual JSON data from the 'data:' field
              if (event.startsWith('data:')) {
                String dataString = event.substring(5).trim();
                final message = json.decode(dataString); // Decode the JSON data

                print("Processing event: $message");

                // Validate the message structure before handling it
                if (message is List && message.isNotEmpty && message[0].containsKey('inboxid') && message[0].containsKey('message')) {
                  handleSseMessage(message[0], activeInboxIds, currentUserId);  // Pass currentUserId here
                } else {
                  print("Invalid message structure: $message");
                }
              }
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

    // Retry logic
    print("Retrying SSE connection...");
    await Future.delayed(Duration(seconds: 5));
    await listenToSse(activeInboxIds, currentUserId);  // Pass currentUserId here as well
  }
}

}
