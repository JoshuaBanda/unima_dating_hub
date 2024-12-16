import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/home/home.dart';  // Import the FarmSmartScreen
import 'package:flutter_secure_storage/flutter_secure_storage.dart';  // Import secure storage

class UpdatePasswordPage extends StatefulWidget {
  final String email;
  final String userId;
  final String firstName;
  final String lastName;
  final String profilePicture;
  final bool activationStatus;

  const UpdatePasswordPage({
    Key? key,
    required this.email,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.activationStatus,
  }) : super(key: key);

  @override
  _UpdatePasswordPageState createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _passwordController = TextEditingController();
  String _message = "";
  bool _isLoading = false;

  // Create an instance of FlutterSecureStorage
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> _updatePassword() async {
    setState(() {
      _isLoading = true;
      _message = "";
    });

    final newPassword = _passwordController.text;

    if (newPassword.isEmpty) {
      setState(() {
        _message = "Please enter the new password.";
        _isLoading = false;
      });
      return;
    }

    // Validate password (at least 8 characters long, contains letters and numbers)
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(newPassword)) {
      setState(() {
        _message = "Password must be at least 8 characters long and contain both letters and numbers.";
        _isLoading = false;
      });
      return;
    }

    try {
      // Send the updated password to the backend
      final response = await http.put(
        Uri.parse('https://datehubbackend.onrender.com/user-aunthentication/update-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = "Password updated successfully!";
          _isLoading = false;
        });

        // Store the email and updated password securely using flutter_secure_storage
        await _secureStorage.write(key: 'email', value: widget.email);  // Store email
        await _secureStorage.write(key: 'password', value: newPassword);  // Store new password

        // Navigate to the FarmSmartScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FarmSmartScreen(),
          ),
        );
      } else {
        setState(() {
          _message = "Failed to update password. Please try again.";
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _message = "Error: $error";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 100),  // Add space at the top to push the input field down
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter your new password',
                border: OutlineInputBorder(),  // Add a border to the text field for better UI
              ),
            ),
            const SizedBox(height: 20),  // Add space between the input and button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,  // Red background color for the button
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isLoading ? null : _updatePassword,
              child: _isLoading
                  ? const SpinKitFadingCircle(color: Colors.white, size: 30.0) 
                  : const Text('Update Password', style: TextStyle(color: Colors.white)),
            ),
            if (_message.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(_message, style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
