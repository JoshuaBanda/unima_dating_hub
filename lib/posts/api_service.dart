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

      print('Response Body for deleting comment: ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(
            'Failed to delete comment. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Failed to delete comment');
    }
  }

  Future<void> updateComment({
  required String jwtToken,
  required int postId,           // This parameter seems unnecessary based on the backend, but I'll leave it here for consistency
  required int commentId,
  required String newCommentText,
}) async {
  if (commentId == null || newCommentText.isEmpty) {
    throw Exception("Invalid parameters for update.");
  }

  try {
    final response = await client.patch(
      Uri.parse('$baseUrl/post-comments/$commentId'),  // Correct URL for comment update
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'comment': newCommentText,  // Corrected body key to match backend parameter (`'comment'`)
      }),
    );

    print('Response Body for updating comment: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      throw Exception(
          'Failed to update comment. Status Code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error updating comment: $e');
    throw Exception('Failed to update comment');
  }
}

}
