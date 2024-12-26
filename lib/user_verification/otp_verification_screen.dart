import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import Timer for countdown
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import Flutter Secure Storage
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import the spin kit package
import '/user_verification/sign_up.dart';
import '/users/user_characteristics/user_characteristics_page.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String firstname;
  final String lastname;
  final String password;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.password,
  });

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  String _message = "";
  late DateTime _otpSentTime;
  bool _isLoading = false; // To control spinner visibility
  late Timer _timer;
  Duration _remainingTime = const Duration(minutes: 10); // 10 minutes countdown

  static const String baseUrl = "https://datehubbackend.onrender.com";
  final Uri verifyOtpUrl = Uri.parse('$baseUrl/users/otp/verify');
  final Uri createUserUrl = Uri.parse('$baseUrl/users/createuser'); // Endpoint to create user

  // Initialize FlutterSecureStorage
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _otpSentTime = DateTime.now();
    _startCountdown();
  }

  // Start countdown timer
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final difference = DateTime.now().difference(_otpSentTime);
      setState(() {
        _remainingTime = const Duration(minutes: 10) - difference;
      });

      // Stop the timer when the remaining time reaches 0
      if (_remainingTime.inSeconds <= 0) {
        _timer.cancel();
      }
    });
  }

  // Verify OTP and then create the user if successful
  Future<void> verifyOtp(String email, String otp) async {
    if (otp.isEmpty || otp.length != 6 || int.tryParse(otp) == null) {
      setState(() {
        _message = "Please enter a valid 6-digit OTP.";
      });
      return;
    }

    setState(() {
      _isLoading = true; // Show spinner while waiting for response
    });

    try {
      final response = await http.post(
        verifyOtpUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // OTP verification successful, proceed with creating the user
        await createUser(email);
      } else {
        setState(() {
          _message = "Invalid OTP. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _message =
            "Error: Unable to verify OTP. Please check your internet connection.";
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide spinner after the response is received
      });
    }
  }

  // Create the user after OTP verification
  Future<void> createUser(String email) async {
    String firstName = widget.firstname;
    String lastName = widget.lastname;
    String password = widget.password;

    setState(() {
      _isLoading = true; // Show spinner while creating user
      _message = ''; // Clear any previous messages
    });

    try {
      final response = await http.post(
        createUserUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'firstname': firstName,
          'lastname': lastName,
          "profilepicture":"default_profile.png",
          'password': password,
        }),
      );

      // Debugging: Print the response status code and body
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        String userId = responseData['user']['userid'].toString();
        String email = responseData['user']['email'];
        String firstName = responseData['user']['firstname'];
        String lastName = responseData['user']['lastname'];
        String accessToken = responseData['access_token'];

        // Store user details and access token in secure storage
        await _storage.write(key: 'userid', value: userId);
        await _storage.write(key: 'email', value: email);
        await _storage.write(key: 'firstname', value: firstName);
        await _storage.write(key: 'lastname', value: lastName);
        await _storage.write(key: 'jwt_token', value: accessToken);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserCharacteristicsPage(userId: userId),
          ),
        );
      }

       else {
        setState(() {
          _message = "Failed to create user. Please try again.";
        });
      }
    } catch (e) {
      print('Error creating user: $e'); // Debugging error
      setState(() {
        _message =
            "Error: Unable to create user. Please check your internet connection.";
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide spinner after user creation response
      });
    }
  }

  // Format remaining time for OTP resend
  String _getFormattedTime(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel(); // Don't forget to cancel the timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // Center the content of the screen
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Countdown timer text in the center
                Text(
                  'OTP expires in: ${_getFormattedTime(_remainingTime)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 30),

                // OTP Input
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    hintText: 'Enter OTP',
                    labelStyle: TextStyle(color: Colors.green.shade700),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Verify OTP Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () =>
                          verifyOtp(widget.email, _otpController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SpinKitFadingCircle(
                          color: Colors.grey, size: 30.0) // Use SpinKit spinner
                      : const Text('Verify OTP',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 20),

                // Message text
                if (_message.isNotEmpty)
                  Text(
                    _message,
                    style: TextStyle(
                      fontSize: 16,
                      color: _message.startsWith('Error') ||
                              _message.startsWith('Invalid')
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
