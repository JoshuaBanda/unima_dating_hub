import 'dart:convert';
import 'package:http/http.dart' as http;
import '/localDataBase/local_database.dart'; // Import the LocalDatabase class
import 'package:unima_dating_hub/notifications/notification_service.dart';
import 'package:unima_dating_hub/notifications/post_notifications_service.dart';

class ChatRepository {
  final String apiUrl;
  Map<String, Map<String, dynamic>> _lastMessageCache = {};

  // Constructor
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

      // If messages exist in local storage, return them
      if (localMessages.isNotEmpty) {
        return localMessages;
      }

      // If no messages in local storage, fetch from server
      final response =
          await http.get(Uri.parse('$apiUrl/message/$inboxId/messageS'));

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
        //await LocalDatabase.saveMessage(inboxId, userId, messageText);
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

  static List<dynamic> _cachedUsers = [];

  static Future<List<dynamic>> fetchUsersToMemory(String userId) async {
    // Check if the users are already cached
    if (_cachedUsers.isNotEmpty) {
      print("Returning cached users");
      return _cachedUsers; // Return cached users
    }

    try {
      final response = await http.get(Uri.parse(
          'https://datehubbackend.onrender.com/inboxparticipants/$userId/chat'));

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        _cachedUsers = users; // Cache the users in the static list
        print("Fetched users from API");
        return users; // Return the users fetched from the API
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Optional: Method to clear the cache if needed (e.g., when the user logs out)
  static void clearCache() {
    _cachedUsers = [];
  }

  // Save received message to the local database
  Future<void> saveReceivedMessage(
      String inboxId, Map<String, dynamic> message) async {
    try {
      // Ensure inboxId and userId are converted to strings if they're integers
      String inboxIdStr = inboxId.toString();
      String userIdStr =
          message['userid'].toString(); // Convert userid to string
      String messageText =
          message['message'] ?? ''; // Safeguard in case 'message' is null

      // Save the message in the local database
      await LocalDatabase.saveMessage(inboxIdStr, userIdStr, messageText);

      // Now, update the last message cache for the given inbox
      _updateLastMessageCache(inboxIdStr, message);
    } catch (e) {
      print("Error saving received message: $e");
    }
  }

  void handleSseMessage(Map<String, dynamic> message,
      List<String> activeInboxIds, String currentUserId) async {
    try {
      String inboxId = message['inboxid'].toString();
      print("Inbox ID: $inboxId");

      if (activeInboxIds.contains(inboxId)) {
        print("Message belongs to an active inbox.");

        // Now, instead of skipping messages from the current user, allow them to be saved
        bool messageExists = await _checkMessageExists(inboxId, message);
        print("Message exists in local storage: $messageExists");

        if (!messageExists) {
          print("Message does not exist. Saving it.");
          await saveReceivedMessage(inboxId, message);
          _updateLastMessageCache(inboxId, message);

          // Fetch user information (first name, last name, profile photo) for the sender
          List<dynamic> users =
              await ChatRepository.fetchUsersToMemory(currentUserId);
          Map<String, dynamic>? sender = users.firstWhere(
              (user) =>
                  user['userid'].toString() == message['userid'].toString(),
              orElse: () => null);

          // If sender is unknown, do not show notification
          if (sender == null) {
            print("Sender is unknown, not showing notification.");
            return;
          }

          // If the sender is the current user, do not show notification
          if ((message['userid']).toString() == currentUserId) {
            print("Sender is the current user, not showing notification.");
          } else {
            // If the message is not from the current user, show the notification
            String senderName = '${sender['firstname']} ${sender['lastname']}';
            String senderProfilePhoto = sender != null &&
                    sender['profilepicture'] != null &&
                    sender['profilepicture'] != ''
                ? '${sender['profilepicture']}'
                : 'default_profile_photo_url'; // Provide a default URL if not available

            // Generate unique notification ID (based on time)
            String notificationId =
                (DateTime.now().millisecondsSinceEpoch % 2147483647).toString();

            // Show the notification with profile image and dynamic ID
            print("Showing notification: $senderName - ${message['message']}");
            await NotificationService.showNotification(
              senderName, // Title
              message['message'] ?? 'No message content', // Body
              senderProfilePhoto, // Profile photo URL
              message['userid'].toString(), // User ID
              notificationId, // Notification ID (this is the dynamic ID)
              currentUserId, // Current User ID
              sender['firstname'] ?? 'First Name', // Sender's First Name
              sender['lastname'] ?? 'Last Name', // Sender's Last Name
              inboxId, // Passing inboxId here from the SSE message
            );

            print("$senderName $notificationId $inboxId");
            print("Notification sent: $senderName - ${message['message']}");
          }
        } else {
          print("Message already exists, not saving.");
        }
      } else {
        print("Message does not belong to any active inbox.");
      }
    } catch (e) {
      print("Error handling SSE message: $e");
    }
  }

  // Check if the message already exists in local storage
  Future<bool> _checkMessageExists(
      String inboxId, Map<String, dynamic> message) async {
    try {
      // Retrieve messages from local storage for the given inboxId
      List<Map<String, dynamic>> localMessages =
          await LocalDatabase.getMessages(inboxId);

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

// The updated function definition
  void listenToSse(
    List<String> inboxIds,
    String userId,
    void Function(Map<String, dynamic>) onNewMessage,
  ) async {
    try {
      final uri = Uri.parse('$apiUrl/message/event');
      print("Initiating SSE connection to: $uri");

      final client = http.Client();
      final request = http.Request('GET', uri);
      request.headers.addAll({
        'Accept': 'text/event-stream',
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        print("SSE connection established successfully.");
        final eventStream = streamedResponse.stream;

        // Listen for incoming events
        await for (var chunk in eventStream) {
          String chunkString = utf8.decode(chunk);
          print("Received k chunk: $chunkString");

          List<String> events = chunkString.split('\n');
          for (var event in events) {
            if (event.isNotEmpty) {
              try {
                if (event.startsWith('data:')) {
                  String dataString = event.substring(5).trim();
                  final message = json.decode(dataString);

                  print("Processing event: $message");

                  if (message is List &&
                      message.isNotEmpty &&
                      message[0].containsKey('inboxid') &&
                      message[0].containsKey('message')) {
                    print("Triggering onNewMessage callback...");
                    onNewMessage(message[0]); // Trigger the callback

                    // Call handleSseMessage here, passing the message and other required parameters
                    print("Calling handleSseMessage...");
                    handleSseMessage(message[0], inboxIds,
                        userId); // <-- This is where we call handleSseMessage

                    print("handleSseMessage has been called.");
                    print("onNewMessage callback triggered.");
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
        print(
            "Error in SSE connection. Status code: ${streamedResponse.statusCode}");
      }
    } catch (e) {
      print("Error listening to SSE: $e");

      // Retry logic with a delay
      print("Retrying SSE connection...");
      await Future.delayed(Duration(seconds: 5));
      listenToSse(inboxIds, userId, onNewMessage); // Retry the connection
    }
  }

  void handleSsePosts(Map<String, dynamic> post, String currentUserId) async {
    try {
      // Fetch user information (first name, last name, profile photo) for the sender
      List<dynamic> users =
          await ChatRepository.fetchUsersToMemory(currentUserId);
      Map<String, dynamic>? sender = users.firstWhere(
          (user) => user['userid'].toString() == post['user_id'].toString(),
          orElse: () => null);

      // If sender is unknown, do not show notification
      if (sender == null) {
        print("Sender is unknown, not showing notification.");
        return;
      }

      // If the post is from the current user, do not show a notification
      //will change the userid to user_id letter
      if ((post['userid']).toString() == currentUserId) {
        print("Sender is the current user, not showing notification.");
      } else {
        // If the message is not from the current user, show the notification
        String senderName = '${sender['firstname']} ${sender['lastname']}';
        String senderProfilePhoto = sender != null &&
                sender['profilepicture'] != null &&
                sender['profilepicture'] != ''
            ? '${sender['profilepicture']}'
            : 'default_profile_photo_url'; // Provide a default URL if not available

        // Generate a unique notification ID (based on time)
        String notificationId =
            (DateTime.now().millisecondsSinceEpoch % 2147483647).toString();

        // Show the notification with profile image and dynamic ID
        print("Showing notification: $senderName - ${post['description']}");
        /*await PostNotificationsService.showNotification(
          senderName, // Title
          post['description'] ?? 'No post desription content', // Body
          senderProfilePhoto, // Profile photo URL
          post['userid'].toString(), // User ID
          notificationId, // Notification ID (this is the dynamic ID)
          currentUserId, // Current User ID
          sender['firstname'] ?? 'First Name', // Sender's First Name
          sender['lastname'] ?? 'Last Name', // Sender's Last Name
          "1",
        );*/
        await PostNotificationsService.showNotification(
          'New Post Title', // Title
          post['description'], // Body
          post['photo_url'], // Photo URL
          post['post_id'].toString(), // Post ID
          post['user_id'].toString(), // User ID
          senderName,
          senderProfilePhoto,
          post['created_at'], // Created At (use appropriate format)
        );


        print("Notification sent: $senderName - ${post['descripyion']}");
      }
    } catch (e) {
      print("Error handling SSE post: $e");
    }
  }

// The updated function definition
  void listenToPostSse(
    List<String> inboxIds,
    String userId,
    void Function(Map<String, dynamic>) onNewPost,
  ) async {
    print("Initializing SSE connection...");
    try {
      final uri = Uri.parse('$apiUrl/message/eventS');
      print("Initiating SSE connection to: $uri");

      final client = http.Client();
      final request = http.Request('GET', uri);
      request.headers.addAll({'Accept': 'text/event-stream'});

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        print("SSE connection established successfully.");
        final eventStream = streamedResponse.stream;

        // Listen for incoming events
        await for (var chunk in eventStream) {
          String chunkString = utf8.decode(chunk);
          print("Received post chunk: $chunkString");

          List<String> events = chunkString.split('\n');
          for (var event in events) {
            if (event.isNotEmpty) {
              try {
                if (event.startsWith('data:')) {
                  String dataString = event.substring(5).trim();
                  final post = json.decode(dataString);

                  print("Processing event: $post");

                  // Ensure that post is a list and check its content
                  if (post is List && post.isNotEmpty) {
                    final firstPost = post[0];

                    // Debug print the firstPost object to ensure the expected structure
                    print("First post object: $firstPost");

                    // Check if the required keys are in the post object
                    if (firstPost.containsKey('post_id') &&
                        firstPost.containsKey('description') &&
                        firstPost.containsKey('photo_url') &&
                        firstPost.containsKey('user_id') &&
                        firstPost.containsKey('created_at')) {
                      print(
                          "Valid message structure. Triggering onNewPost callback...");
                      onNewPost(firstPost); // Trigger the callback

                      // Call handleSsePosts to process further
                      print("Calling handleSsePosts...");
                      handleSsePosts(firstPost, userId);

                      print("handleSsePosts called.");
                      print("onNewPost callback triggered.");
                    } else {
                      print("Invalid post structure. Missing required keys.");
                      print("Post structure: $firstPost");
                    }
                  } else {
                    print("Invalid message structure: $post");
                  }
                }
              } catch (e) {
                print("Error decoding event: $e");
              }
            }
          }
        }
      } else {
        print(
            "Error in SSE connection. Status code: ${streamedResponse.statusCode}");
      }
    } catch (e) {
      print("Error listening to SSE: $e");

      // Retry logic with a delay
      print("Retrying SSE connection...");
      await Future.delayed(Duration(seconds: 5));
      listenToPostSse(inboxIds, userId, onNewPost); // Retry the connection
    }
  }
}
