import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_password_otp.dart';

class RequestNewPassword extends StatefulWidget {
  final String email; // Receive the email from the previous screen

  const RequestNewPassword({super.key, required this.email});  // Constructor to accept email

  @override
  _RequestNewPasswordState createState() => _RequestNewPasswordState();
}

class _RequestNewPasswordState extends State<RequestNewPassword> {
  String _message = "";

  @override
  void initState() {
    super.initState();
    // Automatically send OTP when the screen loads
    sendOtp(widget.email);
  }

  // Send OTP function
  Future<void> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('https://datehubbackend.onrender.com/users/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200 || response.statusCode == 2001) {
        setState(() {
          _message = "An OTP has been successfully sent to $email. Please check your inbox!";
        });
        // Navigate to OTP verification screen after successful OTP request
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NewPasswordVerification(email: email)),
        );
      } else {
        setState(() {
          _message = "Failed to send OTP. Please try again.";
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NewPasswordVerification(email: email)),
        );
      }
    } catch (e) {
      setState(() {
        _message = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center( // Center content in the body
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Friendly instruction message
                const Text(
                  'Hi there! We just need to verify your identity to proceed with resetting your password.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54, // Standard text color
                  ),
                ),
                const SizedBox(height: 20), // Space between text and next content

                // Email display with formatting
                Text(
                  'We have sent a 6-digit verification code to: ${widget.email}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red, // Display email in blue for visibility
                  ),
                ),
                const SizedBox(height: 30), // Space between email and message

                // Additional encouragement or message
                Text(
                  'Please check your inbox, and enter the OTP below to continue.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],  // Standard color for instructions
                  ),
                ),
                const SizedBox(height: 30), // Space between instruction and next content

                // Displaying message (either success or error)
                _message.isNotEmpty
                    ? Text(
                        _message,
                        style: TextStyle(
                          fontSize: 16,
                          color: _message.startsWith('Error') || _message.startsWith('Failed')
                              ? Colors.red // Error message in red
                              : Colors.green,  // Success message in green
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Container(), // If no message, display nothing
              ],
            ),
          ),
        ),
      ),
    );
  }
}
