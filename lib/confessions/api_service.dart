import 'dart:convert';
import 'package:http/http.dart' as http;
import 'connfession/confession.dart';
import 'comments/comments.dart';

class ApiService {
  final String baseUrl =
      'https://datehubbackend.onrender.com'; // Your backend URL
  final http.Client client =
      http.Client(); // Optional: Using a client for better control

  // Fetch all confessions with pagination (page and limit parameters)
  Future<List<Confession>> fetchConfessions(
      {required String jwtToken, int page = 1, int limit = 10}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/confession?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      //print('Response Body : ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Confession.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load confessions. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error fetching confessions: $e');
      throw Exception('Failed to load confessions');
    }
  }

  // Fetch confessions by userId
  Future<List<Confession>> fetchConfessionsByUserId(
      {required String jwtToken, required int userId}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/confession/user/$userId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      //print('Response Body for user $userId: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Confession.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load confessions for user $userId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error fetching confessions by user: $e');
      throw Exception('Failed to load confessions by user');
    }
  }

  // Fetch a single confession by its ID
  Future<Confession> fetchConfessionById(
      {required String jwtToken, required int confessionId}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/confession/$confessionId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      //print('Response Body for confession $confessionId: ${response.body}');

      if (response.statusCode == 200) {
        return Confession.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to load confession by ID $confessionId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error fetching confession by ID: $e');
      throw Exception('Failed to load confession');
    }
  }

  // Fetch comments for a specific confession, including user info (username, profile picture)
  Future<List<Comment>> fetchComments(
      {required String jwtToken, required int confessionId}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/confession-comments/$confessionId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      //print(
        //  'Response Body for comments of confession $confessionId: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Comment.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load comments for confession $confessionId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error fetching comments for confession $confessionId: $e');
      throw Exception('Failed to load comments');
    }
  }

  // Create a comment for a specific confession
  Future<void> createComment(
      {required String jwtToken,
      required int confessionId,
      required String commentText,
      required int userId}) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/confession-comments/create'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'confession_id': confessionId,
          'confession_comment': commentText,
          'user_id': userId,
        }),
      );

      //print('Response Body for creating comment: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception(
            'Failed to add comment. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error adding comment: $e');
      throw Exception('Failed to add comment');
    }
  }

  // Update an existing comment
    Future<void> updateComment({
  required String jwtToken,
  required int confessionId,
  required int commentId,
  required String newCommentText,
}) async {
  if (confessionId == null || commentId == null || newCommentText.isEmpty) {
    throw Exception("Invalid parameters for update.");
  }

  try {
    final response = await client.patch(
      Uri.parse('$baseUrl/confession-comments/$commentId'),  // Correcting to PATCH for update
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'newconfession_Comment': newCommentText,  // Changed to match backend's body parameter
      }),
    );

    //print('Response Body for updating comment: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      throw Exception(
          'Failed to update comment. Status Code: ${response.statusCode}');
    }
  } catch (e) {
    //print('Error updating comment: $e');
    throw Exception('Failed to update comment');
  }
}

  // Delete a comment
  Future<void> deleteComment({
  required String jwtToken,
  required int confessionId,
  required int commentId,
}) async {
  try {
    final response = await client.delete(
      Uri.parse('$baseUrl/confession-comments/$commentId'), // Correct URL
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );

    //print('Response Body for deleting comment: ${response.body}');

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception(
          'Failed to delete comment. Status Code: ${response.statusCode}');
    }
  } catch (e) {
    //print('Error deleting comment: $e');
    throw Exception('Failed to delete comment');
  }
}












Future<bool> likeConfession({
    required String jwtToken,
    required int confessionId,
    required int userId,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/confession-likes/like'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'confessionId': confessionId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic data = response.body;
       // print(" data $data");
        // Successfully liked the confession
        return true; // Return success flag
      } else if (response.statusCode == 409) {
        // Conflict: User has already liked the confession
        throw Exception('User has already liked this confession');
      } else if (response.statusCode == 404) {
        // Not found: the confession might not exist
        throw Exception('Confession not found');
      } else if (response.statusCode == 500) {
        // Server error
        throw Exception('Server error, please try again later');
      } else {
        // Unknown error
        throw Exception(
            'Failed to like confession. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      // General error
      throw Exception('Failed to like confession: $e');
    }
  }

  // Function to remove a like from a confession
  Future<bool> unlikeConfession({
    required String jwtToken,
    required int confessionId,
    required int userId,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/confession-likes/$confessionId/$userId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Successfully removed the like
        return true; // Indicate success
      } else if (response.statusCode == 404) {
        // Like not found
        throw Exception('Like not found for this confession');
      } else if (response.statusCode == 401) {
        // Unauthorized: JWT token might be expired or invalid
        throw Exception('Unauthorized: Please check your credentials');
      } else if (response.statusCode == 500) {
        // Server error
        throw Exception('Server error, please try again later');
      } else {
        throw Exception(
            'Failed to remove like. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      // Log or print the error for debugging purposes
      //print("Error during unlike confession request: $e");
      throw Exception('Failed to remove like: $e');
    }
  }

  Future<bool> isUserLikedConfession({
    required String jwtToken,
    required int confessionId,
    required int userId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/confession-likes/has-liked/$confessionId/$userId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      // Log the response for debugging
      print('is user like confession Response status: ${response.statusCode} $confessionId');
      //print('is user like confession Response body: ${response.body}');

      // Handle success response (status code 200)
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return false; // No likes found for this confession
        }

        // Decode the response body
        final data = jsonDecode(response.body);

        // Log the decoded data
        //print('Decoded data: $data');

        // Handle response format as either List or bool
        if (data is List) {
          return data
              .isNotEmpty; // If it's a list and not empty, the user has liked the confession
        } else if (data is bool) {
          return data; // If it's a boolean value, return it directly (e.g., `true` or `false`)
        } else {
          // Handle unexpected format
          throw Exception('Unexpected response format, expected List or bool');
        }
      } else {
        // Handle failure response
        throw Exception(
            'Failed to check if user liked confession. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error checking if user liked confession: $e');
      throw Exception('Failed to check if user liked confession: $e');
    }
  }

  Future<int> fetchLikesForConfession({
    required String jwtToken,
    required int confessionId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/confession-likes/$confessionId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      // Log the response for debugging
      //print('Response status: ${response.statusCode}');
      //print('Response body afetr getting likes: ${response.body}');

      if (response.statusCode == 200) {
        // Check if the response body is empty
        if (response.body.isEmpty) {
          print('No likes found for this confession');
          return 0; // Return 0 likes if no data is found
        } else {
          // Parse the response body as a list of like objects
          final data = jsonDecode(response.body) as List<dynamic>;

          // Log the decoded data
         // print('Decoded data: $data');

          // Return the number of likes
          return data.length; // Number of likes is the length of the list
        }
      } else {
        throw Exception(
            'Failed to fetch likes for confession $confessionId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error fetching likes: $e');
      throw Exception('Failed to fetch likes: $e');
    }
  }


}
