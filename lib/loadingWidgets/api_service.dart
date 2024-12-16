import 'package:http/http.dart' as http;
import 'dart:convert';
import '/users/users.dart';


class ApiService {
  final String baseUrl = 'http://localhost:3000';

  Future<List<User>> getUser() async {
    final response = await http.get(Uri.parse('$baseUrl/users/allusers'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body); // Cast to List<dynamic>

      // Map each JSON object to a User instance
      return jsonData.map((jsonUser) => User.fromJson(jsonUser)).toList().cast<User>(); // Cast the list to List<User>
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }
}
