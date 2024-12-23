import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';  // Import Timer for countdown
import 'package:flutter_secure_storage/flutter_secure_storage.dart';  // Import Flutter Secure Storage
import '/user_verification/sign_up.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';  // Import the spin kit package
import '/users/user_characteristics/user_characteristics_page.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String currentUserId;
  final String currentUserEmail;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.currentUserId,
    required this.currentUserEmail,
  });

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  String _message = "";
  late DateTime _otpSentTime;
  bool _isLoading = false;  // To control spinner visibility
  late Timer _timer;
  Duration _remainingTime = const Duration(minutes: 10);  // 10 minutes countdown

  static const String baseUrl = "https://datehubbackend.onrender.com";
  final Uri verifyOtpUrl = Uri.parse('$baseUrl/users/otp/verify');
  final Uri resendOtpUrl = Uri.parse('$baseUrl/users/otp/send');

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

  // Verify OTP
  Future<void> verifyOtp(String email, String otp) async {
    if (otp.isEmpty || otp.length != 6 || int.tryParse(otp) == null) {
      setState(() {
        _message = "Please enter a valid 6-digit OTP.";
      });
      return;
    }

    setState(() {
      _isLoading = true;  // Show spinner while waiting for response
    });

    try {
      final response = await http.post(
        verifyOtpUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      // Log status code and response for debugging
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Ensure this line works properly
        final bool activationStatus = responseData['activationstatus'];

        if (activationStatus) {
          // Extract other user details from response
          final String userId = responseData['userid'].toString();
          final String userEmail = responseData['email'];
          final String firstName = responseData['firstname'];
          final String lastName = responseData['lastname'];
          final String profilePicture = responseData['profilepicture'];
          
          // Store user data in secure storage
          await _storage.write(key: 'userid', value: userId);
          await _storage.write(key: 'email', value: userEmail);
          await _storage.write(key: 'firstname', value: firstName);
          await _storage.write(key: 'lastname', value: lastName);
          await _storage.write(key: 'profilepicture', value: profilePicture);

          // Navigate to FarmSmartScreen and pass the required fields
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>UserCharacteristicsPage(userId: widget.currentUserId),
            ),
          );
        } else {
          setState(() {
            _message = "Your account is not activated yet. Please contact support.";
          });
        }
      } else {
        setState(() {
          _message = "Invalid OTP. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error: Unable to verify OTP. Please check your internet connection.";
      });
    } finally {
      setState(() {
        _isLoading = false;  // Hide spinner after the response is received
      });
    }
  }

  // Check if OTP can be resent
  bool canResendOtp() {
    return _remainingTime.inSeconds <= 0;
  }

  // Resend OTP
  Future<void> resendOtp() async {
    if (!canResendOtp()) {
      setState(() {
        _message = "You can resend OTP after ${_getFormattedTime(_remainingTime)}.";
      });
      return;
    }

    setState(() {
      _message = "Resending OTP...";  // Show message when resending OTP
      _isLoading = true;  // Show spinner
    });

    try {
      final response = await http.post(
        resendOtpUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = "OTP resent successfully! Check your email.";
          _otpSentTime = DateTime.now();  // Reset OTP sent time
          _remainingTime = const Duration(minutes: 10);  // Reset countdown
        });
      } else {
        setState(() {
          _message = "Failed to resend OTP. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error: Unable to resend OTP. Please check your internet connection.";
      });
    } finally {
      setState(() {
        _isLoading = false;  // Hide spinner after response
      });
    }
  }

  // Navigate back to the sign-up screen
  void navigateBackToRequestScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  // Format remaining time for OTP resend
  String _getFormattedTime(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();  // Don't forget to cancel the timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Text(
                'Enter the OTP sent to your email:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),
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
              ElevatedButton(
                onPressed: _isLoading ? null : () => verifyOtp(widget.email, _otpController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SpinKitFadingCircle(color: Colors.grey, size: 30.0)  // Use SpinKit spinner
                    : const Text('Verify OTP', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              if (_message.isNotEmpty)
                Text(
                  _message,
                  style: TextStyle(
                    fontSize: 16,
                    color: _message.startsWith('Error') || _message.startsWith('Invalid')
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: resendOtp,
                child: Text(
                  canResendOtp()
                      ? 'Resend OTP'
                      : "Resend available in ${_getFormattedTime(_remainingTime)}",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: navigateBackToRequestScreen,
                child: Text(
                  'Wrong email? Go back and try again.',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
