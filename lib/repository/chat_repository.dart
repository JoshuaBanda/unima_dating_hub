import 'dart:convert';
import 'package:http/http.dart' as http;
import '/localDataBase/local_database.dart';
import 'package:unima_dating_hub/notifications/notification_service.dart';
import 'package:unima_dating_hub/notifications/post_notifications_service.dart';
import 'package:unima_dating_hub/notifications/business_notifications_service.dart';

import 'dart:async';
import 'dart:collection'; // For using Queue

class ChatRepository {
  final String apiUrl;
  Map<String, Map<String, dynamic>> _lastMessageCache = {};

  final int maxRetryAttempts = 5;
  int retryDelaySeconds = 5;
  http.Client? _client; // Nullable client field

  // Constructor
  ChatRepository({required this.apiUrl}); // Lazy initialization of the client
  http.Client get client {
    _client ??= http.Client(); // Initialize only if not already initialized
    return _client!;
  }

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
       // print(localMessages);
        return localMessages;
      }

      // If no messages in local storage, fetch from server
      final response =
          await http.get(Uri.parse('$apiUrl/message/$inboxId/messages'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data.isNotEmpty ? data : [];
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
     //print("Error fetching messages: $e");
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
      String inboxId, String userId, String messageText, String status) async {
    try {
      final requestData = {
        'inboxid': inboxId,
        'userid': userId,
        'message': messageText,
        'status': status,
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
     // print("Returning cached users");
      return _cachedUsers; // Return cached users
    }

    try {
      final response = await http.get(Uri.parse(
          'https://datehubbackend.onrender.com/inboxparticipants/$userId/chat'));

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        _cachedUsers = users; // Cache the users in the static list
       // print("Fetched users from API");
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
          message['userid'].toString(); // Convert userId to string
      String messageText =
          message['message'] ?? ''; // Safeguard in case 'message' is null
      String messageId = message['id'].toString(); // Remote message ID
      String status = 'received'; // Default status for received messages
      String createdAt = message['createdat'] ??
          DateTime.now()
              .toIso8601String(); // Use 'createdat' from message or current time

      // Save the message in the local database
     // print(     "Inserting message: inboxid=$inboxIdStr, userid=$userIdStr, message=$messageText, messageId=$messageId, status=$status, createdAt=$createdAt");
      await LocalDatabase.saveMessage(inboxIdStr, userIdStr, messageText,
          messageId, createdAt, // Pass createdAt as a parameter
          status: status);

      // Now, update the last message cache for the given inbox
      _updateLastMessageCache(inboxIdStr, message);
    } catch (e) {
     // print("Error saving received message: $e");
    }
  }

  void handleSseMessage(Map<String, dynamic> message,
      List<String> activeInboxIds, String currentUserId) async {
    try {
      String inboxId = message['inboxid'].toString();
      //print("Inbox ID: $inboxId");

      if (activeInboxIds.contains(inboxId)) {
        //print("Message belongs to an active inbox.");

        // Now, instead of skipping messages from the current user, allow them to be saved
        bool messageExists = await _checkMessageExists(inboxId, message);
       // print("Message exists in local storage: $messageExists");

        if (!messageExists) {
       //   print("Message does not exist. Saving it. $message");
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
            //print("Sender is unknown, not showing notification.");
            return;
          }

         // print("message id $message");
          // If the sender is the current user, do not show notification
          if ((message['userid']).toString() == currentUserId) {
         //   print("Sender is the current user, not showing notification.");
          } else {
            // Update the message status to 'received'
            //await updateMessageStatus(message[0]['messageId'], 'received');
            await updateMessageStatusToSent(
                message['id'].toString(), 'received');

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
           // print("Showing notification: $senderName - ${message['message']}");
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

          //  print("$senderName $notificationId $inboxId");
          //  print("Notification sent: $senderName - ${message['message']}");
          }
        } else {
        //  print("Message already exists, not saving.");
        }
      } else {
       // print("Message does not belong to any active inbox.");
      }
    } catch (e) {
     // print("Error handling SSE message: $e");
    }
  }

  // Check if the message already exists in local storage
  Future<bool> _checkMessageExists(
      String inboxId, Map<String, dynamic> message) async {
    try {
      // Retrieve messages from local storage for the given inboxId
      List<Map<String, dynamic>> localMessages =
          await LocalDatabase.getMessages(inboxId);

      // Check if any message with the same content and user ID already exists
      for (var storedMessage in localMessages) {
        //print('stored messages : $storedMessage');
        //print('hahahaha ${storedMessage['messageid']}, online ${message['id']}');

        // Compare the message content and user ID (ignore createdat for duplicate check)

        bool isDuplicate =
            storedMessage['messageid'] == message['id'].toString();
        if (isDuplicate) {
          return true; // Message exists in local storage
        }
      }
      return false; // Message does not exist
    } catch (e) {
     // print("Error checking if message exists: $e");
      return false; // Return false if there is an error
    }
  }

  // Listen to SSE (Server-Sent Events) and save new messages to the local database

// SSE connection listener
  Future<void> listenToSse(
    List<String> inboxIds,
    String userId,
    void Function(Map<String, dynamic>) onNewMessage,
  ) async {
    int retryAttempts = 0;
    final inboxIdsParam = inboxIds.join(',');
    final uri = Uri.parse(
      '$apiUrl/message/event?inboxIds=$inboxIdsParam&userId=$userId',
    );

    String buffer = ''; // To buffer incomplete messages
    Queue<Map<String, dynamic>> messageQueue = Queue();

    while (retryAttempts < maxRetryAttempts) {
      try {
        final request = http.Request('GET', uri);
        request.headers.addAll({'Accept': 'text/event-stream'});

        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 201) {
          final eventStream = streamedResponse.stream;

          // Listen for incoming events
          await for (var chunk in eventStream) {
            String chunkString = utf8.decode(chunk);
            buffer += chunkString; // Append chunk to buffer

            // Try processing the buffer if we have a complete message
            while (buffer.contains('data:')) {
              int dataStart = buffer.indexOf('data:') + 5; // Skip 'data:' part
              int dataEnd = buffer.indexOf('\n', dataStart); // Find end of data

              if (dataEnd == -1) {
                break; // Wait for more data if we don't have a full message
              }

              // Extract complete JSON data
              String dataJson = buffer.substring(dataStart, dataEnd).trim();
              buffer = buffer
                  .substring(dataEnd + 1); // Update buffer with remaining data

              // Try to decode the data JSON part
              try {
                final List<dynamic> messages = json.decode(dataJson);
                for (var msg in messages) {
                  if (msg is Map<String, dynamic> &&
                      msg.containsKey('inboxid') &&
                      msg.containsKey('message')) {
                    messageQueue.add(msg); // Add to message queue
                  }
                }

                // Now process the queue
                await processMessageQueue(
                    messageQueue, inboxIds, userId, onNewMessage);
              } catch (e) {
              //  print("Error decoding JSON message: $e");
              //  print("Problematic message data: $dataJson");
              }
            }
          }
        } else {
         // print('Failed to establish SSE connection. Retrying...');
        }
      } catch (e) {
       // print('Error while connecting to SSE: $e');
      }

      // Retry logic with exponential backoff
      retryAttempts++;
      if (retryAttempts < maxRetryAttempts) {
       // print('Retrying SSE connection in $retryDelaySeconds seconds...');
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        retryDelaySeconds *= 2; // Exponential backoff
      } else {
      //  print('Max retry attempts reached.');
        break;
      }
    }
  }

  Future<void> processMessageQueue(
      Queue<Map<String, dynamic>> messageQueue,
      List<String> inboxIds,
      String userId,
      void Function(Map<String, dynamic>) onNewMessage) async {
    // Check if there are messages in the queue
    if (messageQueue.isNotEmpty) {
      // Get the first message in the queue
      Map<String, dynamic> message = messageQueue.first;
      //print("Processing message: $message");

      // Trigger the callback for this message
      onNewMessage(message);

      // Call handleSseMessage here, passing the message and other required parameters
      //print("Calling handleSseMessage...");
      handleSseMessage(message, inboxIds, userId);

      // Remove the processed message from the queue
      messageQueue.removeFirst();
      //print("Message processed and removed from queue. Queue length: ${messageQueue.length}");

      // Ensure the next message is processed
      //print("Checking if more messages are in the queue...");
      if (messageQueue.isNotEmpty) {
        //print( "There are more messages in the queue. Processing next message...");
        await processMessageQueue(messageQueue, inboxIds, userId, onNewMessage);
      } else {
        //print("No more messages in the queue.");
      }
    } else {
      //print("Queue is empty, no message to process.");
    }
  }

  Future<void> processPostQueue(
      Queue<Map<String, dynamic>> postQueue,
      List<String> inboxIds,
      String userId,
      void Function(Map<String, dynamic>) onNewPost) async {
    // Check if there are messages in the queue
    if (postQueue.isNotEmpty) {
      // Get the first message in the queue
      Map<String, dynamic> message = postQueue.first;
      //print("Processing message: $message");

      // Call handleSseMessage here, passing the message and other required parameters
      //print("Calling handleSseMessage...");
      handleSsePosts(message, userId);

      // Remove the processed message from the queue
      postQueue.removeFirst();
      //print("Message processed and removed from queue. Queue length: ${messageQueue.length}");

      // Ensure the next message is processed
      //print("Checking if more messages are in the queue...");
      if (postQueue.isNotEmpty) {
        //print( "There are more messages in the queue. Processing next message...");
        await processPostQueue(postQueue, inboxIds, userId, onNewPost);
      } else {
        //print("No more messages in the queue.");
      }
    } else {
      //print("Queue is empty, no message to process.");
    }
  }

// Helper function to update message status
  Future<void> updateMessageStatusToSent(
      String messageId, String newStatus) async {
    try {
     //print('$messageId $newStatus');
      //change this
      final updateUri = Uri.parse('$apiUrl/message/update');
      final response = await http.put(
        updateUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': messageId,
          'status': newStatus,
        }),
      );
     // print("status code ${response.statusCode}");
      if (response.statusCode == 200) {
       // print("Message status updated to $newStatus. ");
      } else {
        //print(  "Failed to update message status. Status code: ${response.statusCode}");
      }
    } catch (e) {
     // print("Error updating message status: $e");
    }
  }

  Future<void> updateMessageStatusToSeen(
      String messageId, String newStatus) async {
    try {
    //  print('$messageId $newStatus');
      //change this
      final updateUri = Uri.parse('$apiUrl/message/update');
      final response = await http.put(
        updateUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': messageId,
          'status': newStatus,
        }),
      );
     // print("status code ${response.statusCode}");
      if (response.statusCode == 200) {
      //  print("Message status updated to $newStatus. ");
      } else {
        //print(  "Failed to update message status. Status code: ${response.statusCode}");
      }
    } catch (e) {
     // print("Error updating message status: $e");
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
        //print("Sender is unknown, not showing notification.");
        return;
      }

      // If the post is from the current user, do not show a notification
      //will change the userid to user_id letter
      if ((post['userid']).toString() == currentUserId) {
        //print("Sender is the current user, not showing notification.");
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
        //print("Showing notification: $senderName - ${post['description']}");
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
          'New Post', // Title
          post['description'], // Body
          post['photo_url'], // Photo URL
          post['post_id'].toString(), // Post ID
          post['user_id'].toString(), // User ID
          senderName,
          senderProfilePhoto,
          post['created_at'], // Created At (use appropriate format)
        );

        //print("Notification sent: $senderName - ${post['descripyion']}");
      }
    } catch (e) {
      //print("Error handling SSE post: $e");
    }
  }

  void listenToPostSse(
    List<String> inboxIds,
    String userId,
    void Function(Map<String, dynamic>) onNewPost,
  ) async {
    int retryAttempts = 0;
    final uri = Uri.parse('$apiUrl/message/eventS');

    String buffer = ''; // Buffer for incomplete messages
    Queue<Map<String, dynamic>> postQueue = Queue();

    while (retryAttempts < maxRetryAttempts) {
      try {
        final request = http.Request('GET', uri);
        request.headers.addAll({'Accept': 'text/event-stream'});

        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 201) {
          final eventStream = streamedResponse.stream;

          // Listen for incoming events
          await for (var chunk in eventStream) {
            String chunkString = utf8.decode(chunk);
            buffer += chunkString; // Append chunk to buffer

            // Try processing the buffer if we have a complete message
            while (buffer.contains('data:')) {
              int dataStart = buffer.indexOf('data:') + 5; // Skip 'data:' part
              int dataEnd = buffer.indexOf('\n', dataStart); // Find end of data

              if (dataEnd == -1) {
                break; // Wait for more data if we don't have a full message
              }

              // Extract complete JSON data
              String dataJson = buffer.substring(dataStart, dataEnd).trim();
              buffer = buffer
                  .substring(dataEnd + 1); // Update buffer with remaining data

              // Try to decode the data JSON part
              try {
                final List<dynamic> posts = json.decode(dataJson);
                if (posts.isNotEmpty && posts is List) {
                  final firstPost = posts[0];

                  // Validate the structure of the post
                  if (firstPost.containsKey('post_id') &&
                      firstPost.containsKey('description') &&
                      firstPost.containsKey('photo_url') &&
                      firstPost.containsKey('user_id') &&
                      firstPost.containsKey('created_at')) {
                    // Add to the queue
                    postQueue.add(firstPost);

                    // Process the queued posts
                    //await processPostQueue(postQueue, userId, onNewPost);

                    await processPostQueue(
                        postQueue, inboxIds, userId, onNewPost);
                  } else {
                  //  print("Invalid post structure: Missing required keys.");
                  }
                } else {
                 // print("Invalid post message structure.");
                }
              } catch (e) {
              //  print("Error decoding post data: $e");
              //  print("Problematic post data: $dataJson");
              }
            }
          }
        } else {
        //  print('Failed to establish SSE connection. Retrying...');
        }
      } catch (e) {
       // print('Error while connecting to SSE: $e');
      }

      // Retry logic with exponential backoff
      retryAttempts++;
      if (retryAttempts < maxRetryAttempts) {
       // print('Retrying SSE connection in $retryDelaySeconds seconds...');
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        retryDelaySeconds *= 2; // Exponential backoff
      } else {
      //  print('Max retry attempts reached.');
        break;
      }
    }
  }

  Future<void> updateMessage(String messageId, String updatedMessage) async {
    try {
    //  print('updating kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk$messageId');
      //change this
      final updateUri = Uri.parse('$apiUrl/messager/updatemessagetext');
      final response = await http.put(
        updateUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': messageId,
          'message': updatedMessage,
        }),
      );
     // print("status code ${response.statusCode}");
      if (response.statusCode == 200) {
      //  print("Message updated to $updatedMessage. ");
      } else {
        //print(  "Failed to update message status. Status code: ${response.statusCode}");
      }
    } catch (e) {
     // print("Error updating message status: $e");
    }
  }

  Future<void> deleteMessage(String inboxId, String messageId) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/messages/$messageId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete message');
    }
  }

  void listenToStatusSse(
    List<String> inboxIds,
    String userId,
  ) async {
    int retryAttempts = 0;
    int retryDelaySeconds = 5; // Initial retry delay in seconds
    final uri = Uri.parse(
        '$apiUrl/message/statusSse?inboxIds=${inboxIds.join(',')}&userId=$userId');

    String buffer = ''; // Buffer for incomplete messages
    Queue<Map<String, dynamic>> statusQueue = Queue(); // Queue to store events

    while (retryAttempts < maxRetryAttempts) {
      try {
        final client = http.Client();
        final request = http.Request('GET', uri);
        request.headers.addAll({'Accept': 'text/event-stream'});

        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 201) {
          final eventStream = streamedResponse.stream;

          // Listen for incoming events
          await for (var chunk in eventStream) {
            String chunkString = utf8.decode(chunk);
            buffer += chunkString; // Append chunk to buffer

            // Try processing the buffer if we have a complete message
            while (buffer.contains('data:')) {
              int dataStart = buffer.indexOf('data:') + 5; // Skip 'data:' part
              int dataEnd = buffer.indexOf('\n', dataStart); // Find end of data

              if (dataEnd == -1) {
                break; // Wait for more data if we don't have a full message
              }

              // Extract complete JSON data
              String dataJson = buffer.substring(dataStart, dataEnd).trim();
              buffer = buffer
                  .substring(dataEnd + 1); // Update buffer with remaining data

              // Try to decode the data JSON part
              try {
                final List<dynamic> messages = json.decode(dataJson);
                for (var msg in messages) {
                  if (msg is Map<String, dynamic> &&
                      msg.containsKey('inboxid')) {
                    statusQueue.add(msg); // Add valid message to the queue
                  }
                }

                // Process the queued status messages
                await processStatusQueue(statusQueue, inboxIds, userId);
              } catch (e) {
               // print("Error decoding status message: $e");
               // print("Problematic status message: $dataJson");
              }
            }
          }
        } else {
          //print('Error in SSE connection. Status code: ${streamedResponse.statusCode}');
        }
      } catch (e) {
       // print('Error while connecting to SSE: $e');
      }

      // Retry logic with exponential backoff
      retryAttempts++;
      if (retryAttempts < maxRetryAttempts) {
      //  print('Retrying SSE connection in $retryDelaySeconds seconds...');
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        retryDelaySeconds *= 2; // Exponential backoff
      } else {
      //  print('Max retry attempts reached.');
        break;
      }
    }
  }

  Future<void> processStatusQueue(
    Queue<Map<String, dynamic>> statusQueue,
    List<String> inboxIds,
    String userId,
  ) async {
    // Process the queue until it's empty
    while (statusQueue.isNotEmpty) {
      // Get and remove the first message in the queue
      Map<String, dynamic> message = statusQueue.removeFirst();
      //print("Processing message: $message");

      try {
        // Call handleSseStatus here, passing the message and other required parameters
        //print("Calling handleSseStatus... $message, $inboxIds, $userId");
        handleSseStatus(
            message, inboxIds, userId); // Make sure it's async if needed

        // Debugging message removal and queue length
      // print("Message processed and removed from queue. Queue length: ${statusQueue.length}");
      } catch (e) {
        // Error handling: If an error occurs while processing a message, log it
       // print("Error processing message: $e. Message: $message");
        // You could decide to re-add the message to the queue for later retry or handle the error as appropriate
      }
    }

    // Once the queue is empty, notify that no more status events remain
   // print("No more status in the queue.");
  }

  void handleSseStatus(Map<String, dynamic> message,
      List<String> activeInboxIds, String currentUserId) async {
    if ((message['userid']).toString() == currentUserId) {}
    try {
      String inboxId =
          message['inboxid'].toString(); // Ensure inboxId is a string
      String messageId = message['id']
          .toString(); // Convert messageId to string if it's an integer
      //print("Inbox ID: $inboxId");

      String newStatus =
          message['status'].toString(); // Ensure newStatus is a string
    //  print("");
      if (activeInboxIds.contains(inboxId)) {
        //print("Message belongs to an active inbox.");

        //print('updating status in local database id $messageId, new status $newStatus');

        // Update the status in the local database
        await LocalDatabase.updateMessageStatus(messageId, newStatus);

        // Retrieve the last message in the inbox after update
        await LocalDatabase.getLastMessage(inboxId);

        // Update the last message cache (if needed)
        _updateLastMessageCache(inboxId, message);
      } else {
       // print("Message does not belong to any active inbox.");
      }
    } catch (e) {
      //print("Error handling SSE message: $e");
    }
  }

  // Check if the message already exists in local storage

  void listenToBusinessSse(
    List<String> inboxIds,
    String userId,
    void Function(Map<String, dynamic>) onNewBusiness,
  ) async {
    int retryAttempts = 0;
    //we change the api
    final uri = Uri.parse('$apiUrl/message/business-sse');

    String buffer = ''; // Buffer for incomplete messages
    Queue<Map<String, dynamic>> businessQueue = Queue();

    while (retryAttempts < maxRetryAttempts) {
      try {
        final request = http.Request('GET', uri);
        request.headers.addAll({'Accept': 'text/event-stream'});

        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 201) {
          //print("connection initialised");
          final eventStream = streamedResponse.stream;

          // Listen for incoming events
          await for (var chunk in eventStream) {
            String chunkString = utf8.decode(chunk);
            buffer += chunkString; // Append chunk to buffer

            // Try processing the buffer if we have a complete message
            while (buffer.contains('data:')) {
              int dataStart = buffer.indexOf('data:') + 5; // Skip 'data:' part
              int dataEnd = buffer.indexOf('\n', dataStart); // Find end of data

              if (dataEnd == -1) {
                break; // Wait for more data if we don't have a full message
              }

              // Extract complete JSON data
              String dataJson = buffer.substring(dataStart, dataEnd).trim();
              buffer = buffer
                  .substring(dataEnd + 1); // Update buffer with remaining data

              // Try to decode the data JSON part
              try {
                final List<dynamic> businesses = json.decode(dataJson);
                if (businesses.isNotEmpty && businesses is List) {
                  final firstBusiness = businesses[0];

                  // Validate the structure of the post
                  if (firstBusiness.containsKey('business_id') &&
                      firstBusiness.containsKey('description') &&
                      firstBusiness.containsKey('photo_url') &&
                      firstBusiness.containsKey('user_id') &&
                      firstBusiness.containsKey('created_at')) {
                    // Add to the queue
                    businessQueue.add(firstBusiness);

                    // Process the queued posts
                    //await processPostQueue(postQueue, userId, onNewPost);

                    await processBusinessQueue(
                        businessQueue, inboxIds, userId, onNewBusiness);
                  } else {
                //    print("Invalid business structure: Missing required keys.");
                  }
                } else {
              //    print("Invalid business message structure.");
                }
              } catch (e) {
                //print("Error decoding business data: $e");
              //  print("Problematic business data: $dataJson");
              }
            }
          }
        } else {
         // print('Failed to establish Business SSE connection. Retrying...');
        }
      } catch (e) {
       // print('Error while connecting to business SSE: $e');
      }

      // Retry logic with exponential backoff
      retryAttempts++;
      if (retryAttempts < maxRetryAttempts) {
       // print('Retrying SSE connection in $retryDelaySeconds seconds...');
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        retryDelaySeconds *= 2; // Exponential backoff
      } else {
      //  print('Max retry attempts reached.');
        break;
      }
    }
  }

  void handleSseBusiness(
      Map<String, dynamic> business, String currentUserId) async {
    try {
      //

      // If the business is from the current user, do not show a notification
      //will change the userid to user_id letter
      if ((business['userid']).toString() == currentUserId) {
        //print("Sender is the current user, not showing notification.");
      } else {
        // If the message is not from the current user, show the notification
        String senderName = "Business";
        String senderProfilePhoto = business['photo_url'];

        // Generate a unique notification ID (based on time)
        String notificationId =
            (DateTime.now().millisecondsSinceEpoch % 2147483647).toString();

       // print("kkkkkkkkkkkkkkkkkkkkkkkkk $business");
        await BusinessNotificationsService.showNotification(
          'Business Around Campus', // Title
          business['description'], // Body
          business['photo_url'], // Photo URL
          business['business_id'].toString(),
          business['user_id'].toString(), // User ID
          senderName,
          senderProfilePhoto,
          business['created_at'], // Created At (use appropriate format)
        );

       // print("Notification sent: $senderName - ${business['description']}");
      }
    } catch (e) {
      //print("Error handling SSE post: $e");
    }
  }

  Future<void> processBusinessQueue(
      Queue<Map<String, dynamic>> businessQueue,
      List<String> inboxIds,
      String userId,
      void Function(Map<String, dynamic>) onNewBusiness) async {
    // Check if there are messages in the queue
    if (businessQueue.isNotEmpty) {
      // Get the first message in the queue
      Map<String, dynamic> message = businessQueue.first;
      //print("Processing message: $message");

      // Call handleSseMessage here, passing the message and other required parameters
     // print("Calling handlebusinnes...");
      handleSseBusiness(message, userId);

      // Remove the processed message from the queue
      businessQueue.removeFirst();
      //print("Message processed and removed from queue. Queue length: ${messageQueue.length}");

      // Ensure the next message is processed
      //print("Checking if more messages are in the queue...");
      if (businessQueue.isNotEmpty) {
        //print( "There are more messages in the queue. Processing next message...");
        await processBusinessQueue(
            businessQueue, inboxIds, userId, onNewBusiness);
      } else {
        //print("No more messages in the queue.");
      }
    } else {
      //print("Queue is empty, no message to process.");
    }
  }

  
  Future<void> block(int inboxId, int blocker) async {
    try {
      //print('updating kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk$messageId');
      //change this
      final updateUri = Uri.parse('$apiUrl/inbox/block');
      final response = await http.put(
        updateUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inboxid': inboxId,
          'blocker': blocker,
        }),
      );
     // print("status code ${response.statusCode}");
      if (response.statusCode == 200) {

        
        
     //   print("blocked. ");
      } else {
        //print(  "Failed to update message status. Status code: ${response.statusCode}");
      }
    } catch (e) {
     // print("Error updating message status: $e");
    }
  }

  
  Future<void> unblock(int inboxId,int blocker) async {
    try {
      //print('updating kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk$messageId');
      //change this
      final updateUri = Uri.parse('$apiUrl/inbox/unblock');
      final response = await http.put(
        updateUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inboxid': inboxId,
          'blocker': blocker,
        }),
      );
     // print("status code ${response.statusCode}");
      if (response.statusCode == 200) {
       // print("unblock ");
      } else {
        //print(  "Failed to update message status. Status code: ${response.statusCode}");
      }
    } catch (e) {
     // print("Error updating message status: $e");
    }
  }
}

class MessageStatus {
  final int id;
  final String status;
  final int inboxid;
  final int userid;

  MessageStatus({
    required this.id,
    required this.status,
    required this.inboxid,
    required this.userid,
  });
}
