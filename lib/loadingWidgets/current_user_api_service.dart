import 'package:http/http.dart' as http;
import 'dart:convert';
import '/users/users.dart'; // Ensure you have the User model defined here


class CurrentUserApiService{
  final String baseUrl='http://localhost:3000';

  Future<User> getCurrentUser(int userid) async {
    final response=await http.get(Uri.parse('$baseUrl/users/$userid'));

    if (response.statusCode==200||response.statusCode == 201){
      final jsonData=jsonDecode(response.body);
      return User.fromJson(jsonData);
    }else{
      throw Exception('Failed to load current user');
    }
  }
}