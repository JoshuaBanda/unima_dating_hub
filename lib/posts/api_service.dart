import 'dart:convert';
import 'package:http/http.dart' as http;
import 'post/post.dart';
import 'comments/comments.dart';

class ApiService {
  final String baseUrl = 'https://datehubbackend.onrender.com'; // Your backend URL
  final http.Client client = http.Client(); // Optional: Using a client for better control

  // Fetch all posts with pagination (page and limit parameters)
  Future<List<Post>> fetchPosts({required String jwtToken, int page = 1, int limit = 10}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Post.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load posts. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      throw Exception('Failed to load posts');
    }
  }

  // Fetch posts by userId
  Future<List<Post>> fetchPostsByUserId({required String jwtToken, required int userId}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post/user/$userId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response Body for user $userId: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Post.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load posts for user $userId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts by user: $e');
      throw Exception('Failed to load posts by user');
    }
  }

  // Fetch a single post by its ID
  Future<Post> fetchPostById({required String jwtToken, required int postId}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post/$postId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response Body for post $postId: ${response.body}');

      if (response.statusCode == 200) {
        return Post.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load post by ID $postId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching post by ID: $e');
      throw Exception('Failed to load post');
    }
  }

  // Fetch comments for a specific post, including user info (username, profile picture)
  Future<List<Comment>> fetchComments({required String jwtToken, required int postId}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/post-comments/$postId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response Body for comments of post $postId: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Comment.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load comments for post $postId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching comments for post $postId: $e');
      throw Exception('Failed to load comments');
    }
  }

  // Create a comment for a specific post
  Future<void> createComment({required String jwtToken, required int postId, required String commentText, required int userId}) async {
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

      print('Response Body for creating comment: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception('Failed to add comment. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment');
    }
  }
}
