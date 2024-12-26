import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import for TimeoutException
import 'otp_verification_screen.dart';  // Import the OTP verification screen

class OtpRequestScreen extends StatefulWidget {
  final String email; // Receive the email from the previous screen
  final String firstName; // Accept first name
  final String lastName; // Accept last name
  final String password; // Accept password

  const OtpRequestScreen({
    super.key, 
    required this.email, 
    required this.firstName, // Accept firstName
    required this.lastName, // Accept lastName
    required this.password, // Accept password
  });

  @override
  _OtpRequestScreenState createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends State<OtpRequestScreen> {
  String _message = "";

  @override
  void initState() {
    super.initState();
    // Automatically send OTP when the screen loads
    sendOtp(widget.email);
  }

  // Send OTP function with timeout increased to 60 seconds
  Future<void> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('https://datehubbackend.onrender.com/users/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 60)); // Increased timeout to 60 seconds

      // Print the response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _message = "An OTP has been successfully sent to $email. Please check your inbox!";
        });

        // Navigate to OTP verification screen after successful OTP request
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: email,
              firstname: widget.firstName,  // Pass first name
              lastname: widget.lastName,  // Pass last name
              password: widget.password,  // Pass password
            ),
          ),
        );
      } else {
        setState(() {
          _message = "Failed to send OTP. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        if (e is TimeoutException) {
          _message = "Request timed out. Please try again later.";
        } else {
          _message = "Error: $e";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],  // Set background color
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),  // Adjusted vertical padding
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4), // Shadow effect
                ),
              ],
            ),
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'This will not take much time!!!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54, // Standard text color
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'A verification OTP has been sent to ${widget.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700], // Email display color
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_message.isNotEmpty)
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: _message.startsWith('Error') || _message.startsWith('Failed')
                            ? Colors.red // Error message in red
                            : Colors.green,  // Success message in green
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
