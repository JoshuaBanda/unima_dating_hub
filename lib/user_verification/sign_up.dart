import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'Login_SignUp.dart'; // Import LoginPage
import 'otp_request_screen.dart'; // Import OTP request screen

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController(); // Last name controller
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // State for loading indicator
  String _errorMessage = '';

  // Secure storage instance to store JWT
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // API endpoint for registration
  final String _apiUrl = 'https://datehubbackend.onrender.com/users/createuser'; // Replace with your actual API URL

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Create a new account",
                  style: TextStyle(fontSize: screenWidth * 0.05,color: Colors.red),
                ),
                const SizedBox(height: 50),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: firstnameController,
                        hintText: 'Enter first name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: lastNameController,
                        hintText: 'Enter last name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: emailController,
                        hintText: 'Enter email',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                              .hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: passwordController,
                        hintText: 'Enter password',
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: Size(screenWidth * 0.8, 50),
                        ),
                        child: _isLoading
                            ? const SpinKitFadingCircle(color: Colors.grey, size: 50.0)
                            : const Text('SIGN UP', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            },
                            child: Text(
                              'Log In',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;  // Show spinner
        _errorMessage = '';  // Reset error message
      });

      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'firstname': firstnameController.text.trim(),
            'lastname': lastNameController.text.trim(),
            'profilepicture': 'default.jpg',
            'email': emailController.text.trim(),
            'password': passwordController.text.trim(),
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final user = responseData['user'];
          final String token = responseData['access_token'];
          final String userId = user['userid'].toString();
          final String userEmail = user['email'];

          await _storage.write(key: 'jwt_token', value: token);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpRequestScreen(
                email: userEmail,
                currentUserId: userId,
                currentUserEmail: userEmail,
              ),
            ),
          );
        } else {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to create account.';
          });
        }
      } catch (e) {
        if (e is http.ClientException) {
          setState(() {
            _errorMessage = 'No internet connection. Please try again later.';
          });
        } else if (e is TimeoutException) {
          setState(() {
            _errorMessage = 'Request timed out. Please try again later.';
          });
        } else {
          setState(() {
            _errorMessage = 'An unexpected error occurred.';
          });
        }
      } finally {
        setState(() {
          _isLoading = false;  // Hide spinner after request completes
        });
      }
    }
  }
}
