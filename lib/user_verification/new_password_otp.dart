import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'update_password_page.dart'; // Import your UpdatePasswordPage
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';

class NewPasswordVerification extends StatefulWidget {
  final String email;
  const NewPasswordVerification({super.key, required this.email});

  @override
  _NewPasswordVerificationState createState() =>
      _NewPasswordVerificationState();
}

class _NewPasswordVerificationState extends State<NewPasswordVerification> {
  final TextEditingController _otpController = TextEditingController();
  String _message = "";
  bool _isLoading = false;
  late DateTime _otpSentTime;
  late Timer _timer;
  int _otpExpiryTime = 600; // OTP expiry time in seconds (10 minutes)

  @override
  void initState() {
    super.initState();
    _otpSentTime = DateTime.now(); // Record when OTP was sent
    _startCountdown(); // Start the countdown timer
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Function to verify OTP
  Future<void> verifyOtp(String email, String otp) async {
    setState(() {
      _isLoading = true;
      _message = "";
    });

    try {
      final response = await http.post(
        Uri.parse('https://datehubbackend.onrender.com/users/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      // Check if the widget is still mounted before calling setState
      if (!mounted) return;

      // Print the response body to verify the structure
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // If the response body is empty, still proceed to the next steps
        try {
          if (response.body.isNotEmpty) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            final bool? activationStatus = responseData['activationstatus'];

            if (activationStatus != null && activationStatus) {
              final user = responseData; // Directly use the response data

              // Extract user data
              final String userId = user['userid'].toString();
              final String firstName = user['firstname'];
              final String lastName = user['lastname'];
              final String profilePicture = user['profilepicture'];
              final String email = user['email'];

              // Pass user data to UpdatePasswordPage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UpdatePasswordPage(
                    email: widget.email,
                    userId: userId,
                    firstName: firstName,
                    lastName: lastName,
                    profilePicture: profilePicture,
                    activationStatus: activationStatus,
                  ),
                ),
              );
            } else {
              setState(() {
                _message = "Your account is not activated yet.";
                _isLoading = false;
              });
            }
          } else {
            // If the response body is empty, continue without the user data
            setState(() {
              _message = "OTP verified successfully, but no data received.";
              _isLoading = false;
            });
            // Proceed with your desired flow even if no user data is available
            // For example, navigate to UpdatePasswordPage or some other page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UpdatePasswordPage(
                  email: widget.email, // Pass the email for password reset
                  userId: "",  // You can pass an empty string or null if no user data
                  firstName: "",
                  lastName: "",
                  profilePicture: "",
                  activationStatus: false, // You can set the default value if necessary
                ),
              ),
            );
          }
        } catch (e) {
          setState(() {
            _message = "Error decoding response: $e";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _message = "Failed to verify OTP. Please try again.";
          _isLoading = false;
        });
      }
    } catch (e) {
      // Check if the widget is still mounted before calling setState
      if (!mounted) return;

      setState(() {
        _message = "Error: $e";
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpExpiryTime > 0) {
        setState(() {
          _otpExpiryTime--;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100), // Adjust the space at the top
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20), // Add spacing between the input and the button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red background color for the button
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (_otpController.text.isNotEmpty) {
                  verifyOtp(widget.email, _otpController.text);
                } else {
                  setState(() {
                    _message = "Please enter the OTP.";
                  });
                }
              },
              child: Text(
                "Verify OTP",
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (_isLoading) const SpinKitFadingCircle(color: Colors.grey, size: 50.0),
            if (_message.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(_message, style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 20),
            Text("OTP expires in: ${_formatTime(_otpExpiryTime)}"),
          ],
        ),
      ),
    );
  }
}
