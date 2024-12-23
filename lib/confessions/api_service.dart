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

      print('Response Body : ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Confession.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load confessions. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching confessions: $e');
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

      print('Response Body for user $userId: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Confession.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load confessions for user $userId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching confessions by user: $e');
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

      print('Response Body for confession $confessionId: ${response.body}');

      if (response.statusCode == 200) {
        return Confession.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to load confession by ID $confessionId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching confession by ID: $e');
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

      print(
          'Response Body for comments of confession $confessionId: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Comment.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load comments for confession $confessionId. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching comments for confession $confessionId: $e');
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
          'comment': commentText,
          'user_id': userId,
        }),
      );

      print('Response Body for creating comment: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception(
            'Failed to add comment. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment');
    }
  }
}
