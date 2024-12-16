import 'dart:convert';
import 'package:http/http.dart' as http;
import '/localDataBase/local_database.dart'; // Import the LocalDatabase class

class ChatRepository {
  final String apiUrl;

  ChatRepository({required this.apiUrl});

  // Fetch inbox data for a user
  Future<Map<String, dynamic>> fetchInboxData(
      String userId, String myUserId) async {
    try {
      final response = await http.get(Uri.parse(
          '$apiUrl/inboxparticipants/currentinbox/$userId/$myUserId'));
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
      List<Map<String, dynamic>> localMessages =
          await LocalDatabase.getMessages(inboxId);
      print("Fetched messages from local storage: $localMessages");

      // If messages exist in local storage, return them
      if (localMessages.isNotEmpty) {
        return localMessages;
      }

      // If no messages in local storage, fetch from server
      final response =
          await http.get(Uri.parse('$apiUrl/message/$inboxId/message'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Fetched messages from server: $data");
        return data.isNotEmpty ? data : [];
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  // Send a new message
  Future<void> sendMessage(
      String inboxId, String userId, String messageText) async {
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
        print("Message saved locally: $messageText"); // Log to confirm saving
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
      final response =
          await http.get(Uri.parse('$apiUrl/inboxparticipants/$userId/chat'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }
}
