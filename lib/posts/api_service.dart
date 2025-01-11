import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'post/post.dart';
import 'comments/comments.dart';

class ApiService {
  final String baseUrl =
      'https://datehubbackend.onrender.com'; // Your backend URL
  final http.Client client =
      http.Client(); // Optional: Using a client for better control
  final FlutterSecureStorage _storage =
      const FlutterSecureStorage(); // For secure storage of email/password

  // Fetch all posts with pagination (page and limit parameters)
  Future<List<Post>> fetchPosts(
      {required String jwtToken, int page = 1, int limit = 10}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Post.fromJson(item)).toList();
      } else if (response.statusCode == 403) {
        // Handle 403 error: Token may have expired
        String? newToken = await _refreshToken();
        if (newToken != null) {
          return await fetchPosts(jwtToken: newToken, page: page, limit: limit);
        } else {
          throw Exception('Failed to refresh token');
        }
      } else {
        throw Exception(
            'Failed to load posts. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load posts');
    }
  }

  // Fetch posts by userId
  Future<List<Post>> fetchPostsByUserId(
      {required String jwtToken, required int userId}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post/user/$userId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Post.fromJson(item)).toList();
      } else if (response.statusCode == 403) {
        // Handle 403 error: Token may have expired
        String? newToken = await _refreshToken();
        if (newToken != null) {
          return await fetchPostsByUserId(jwtToken: newToken, userId: userId);
        } else {
          throw Exception('Failed to refresh token');
        }
      } else {
        throw Exception(
            'Failed to load posts for user $userId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load posts by user');
    }
  }

  // Fetch a single post by its ID
  Future<Post> fetchPostById(
      {required String jwtToken, required int postId}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post/$postId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Post.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        // Handle 403 error: Token may have expired
        String? newToken = await _refreshToken();
        if (newToken != null) {
          return await fetchPostById(jwtToken: newToken, postId: postId);
        } else {
          throw Exception('Failed to refresh token');
        }
      } else {
        throw Exception(
            'Failed to load post by ID $postId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load post');
    }
  }

  // Fetch comments for a specific post
  Future<List<Comment>> fetchComments(
      {required String jwtToken, required int postId}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post-comments/$postId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Comment.fromJson(item)).toList();
      } else if (response.statusCode == 403) {
        // Handle 403 error: Token may have expired
        String? newToken = await _refreshToken();
        if (newToken != null) {
          return await fetchComments(jwtToken: newToken, postId: postId);
        } else {
          throw Exception('Failed to refresh token');
        }
      } else {
        throw Exception(
            'Failed to load comments for post $postId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load comments');
    }
  }

  // Create a comment for a specific post
  Future<void> createComment(
      {required String jwtToken,
      required int postId,
      required String commentText,
      required int userId}) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/post-comments/create'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'post_id': postId,
          'comment': commentText,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception(
            'Failed to add comment. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add comment');
    }
  }

  // Function to refresh the JWT token by logging in again
  Future<String?> _refreshToken() async {
    try {
      String? email = await _storage.read(key: 'email');
      String? password = await _storage.read(key: 'password');

      if (email != null && password != null) {
        final response = await client.post(
          Uri.parse('$baseUrl/users/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          String newToken = responseData['access_token'];

          // Store the new token in secure storage
          await _storage.write(key: 'jwt_token', value: newToken);

          return newToken;
        } else {
          throw Exception('Failed to refresh token');
        }
      } else {
        throw Exception('No stored credentials found');
      }
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  Future<void> deleteComment({
    required String jwtToken,
    required int postId,
    required int commentId,
  }) async {
    if (postId == null || commentId == null) {
      throw Exception("Invalid postId or commentId");
    }

    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/post-comments/$commentId'),
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

  Future<void> updateComment({
    required String jwtToken,
    required int
        postId, // This parameter seems unnecessary based on the backend, but I'll leave it here for consistency
    required int commentId,
    required String newCommentText,
  }) async {
    if (commentId == /*null*/0 || newCommentText.isEmpty) {
      throw Exception("Invalid parameters for update.");
    }

    try {
      final response = await client.patch(
        Uri.parse(
            '$baseUrl/post-comments/$commentId'), // Correct URL for comment update
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'comment':
              newCommentText, // Corrected body key to match backend parameter (`'comment'`)
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

  Future<bool> likePost({
    required String jwtToken,
    required int postId,
    required int userId,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/post-likes/like'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'postId': postId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic data = response.body;
       // print(" data $data");
        // Successfully liked the post
        return true; // Return success flag
      } else if (response.statusCode == 409) {
        // Conflict: User has already liked the post
        throw Exception('User has already liked this post');
      } else if (response.statusCode == 404) {
        // Not found: the post might not exist
        throw Exception('Post not found');
      } else if (response.statusCode == 500) {
        // Server error
        throw Exception('Server error, please try again later');
      } else {
        // Unknown error
        throw Exception(
            'Failed to like post. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      // General error
      throw Exception('Failed to like post: $e');
    }
  }

  // Function to remove a like from a post
  Future<bool> unlikePost({
    required String jwtToken,
    required int postId,
    required int userId,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/post-likes/$postId/$userId'),
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
        throw Exception('Like not found for this post');
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
      //print("Error during unlike post request: $e");
      throw Exception('Failed to remove like: $e');
    }
  }

  Future<bool> isUserLikedPost({
    required String jwtToken,
    required int postId,
    required int userId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post-likes/has-liked/$postId/$userId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      // Log the response for debugging
      //print('is user like post Response status: ${response.statusCode}');
      //print('is user like post Response body: ${response.body}');

      // Handle success response (status code 200)
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return false; // No likes found for this post
        }

        // Decode the response body
        final data = jsonDecode(response.body);

        // Log the decoded data
        //print('Decoded data: $data');

        // Handle response format as either List or bool
        if (data is List) {
          return data
              .isNotEmpty; // If it's a list and not empty, the user has liked the post
        } else if (data is bool) {
          return data; // If it's a boolean value, return it directly (e.g., `true` or `false`)
        } else {
          // Handle unexpected format
          throw Exception('Unexpected response format, expected List or bool');
        }
      } else {
        // Handle failure response
        throw Exception(
            'Failed to check if user liked post. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error checking if user liked post: $e');
      throw Exception('Failed to check if user liked post: $e');
    }
  }

  Future<int> fetchLikesForPost({
    required String jwtToken,
    required int postId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post-likes/$postId'),
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
         // print('No likes found for this post');
          return 0; // Return 0 likes if no data is found
        } else {
          // Parse the response body as a list of like objects
          final data = jsonDecode(response.body) as List<dynamic>;

          // Log the decoded data
          //print('Decoded data: $data');

          // Return the number of likes
          return data.length; // Number of likes is the length of the list
        }
      } else {
        throw Exception(
            'Failed to fetch likes for post $postId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error fetching likes: $e');
      throw Exception('Failed to fetch likes: $e');
    }
  }
}
