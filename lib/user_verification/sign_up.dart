import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'otp_request_screen.dart'; // Import OTP request screen
import 'Login_SignUp.dart';
import 'package:google_fonts/google_fonts.dart';

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
                    "Create Account", // Text displayed on top
                    style: GoogleFonts.sourceSansPro(
                      textStyle: TextStyle(
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [
                              Colors.pink,
                              const Color.fromARGB(255, 253, 183, 77),
                              Colors.red
                            ],
                          ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                        fontStyle: FontStyle.normal,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: 50),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled, // Only validate on submit
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: firstnameController,
                        hintText: 'Enter first name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          if (value.length > 50) {
                            return 'First name should not be too long';
                          }
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                            return 'Please enter a valid name (letters only)';
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
                          if (value.length > 50) {
                            return 'Last name should not be too long';
                          }
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                            return 'Please enter a valid name (letters only)';
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
                          if (!RegExp(r"^[a-zA-Z0-9._%+-]+@unima\.ac\.mw$").hasMatch(value)) {
                            return 'Please enter a valid school email (ending with @unima.ac.mw)';
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
                          backgroundColor: Colors.white,
                          minimumSize: Size(screenWidth * 0.4, 50),
                        ),
                        child: _isLoading
                            ? const SpinKitFadingCircle(color: Colors.grey, size: 50.0)
                            : const Text('SIGN UP', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?"),
                          TextButton(
                            onPressed: () {
                              // Navigate to Login page when clicked
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
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
        ),
      ),
      validator: validator,
    );
  }

  // Handle the Sign-Up process
  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;  // Show spinner
        _errorMessage = '';  // Reset error message
      });

      // Simulate a successful sign-up (you can remove this part if you're connecting to a backend)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;  // Hide spinner
      });

      // After successful "sign-up", pass values to OTP screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtpRequestScreen(
            email: emailController.text.trim(),
            firstName: firstnameController.text.trim(),
            lastName: lastNameController.text.trim(),
            password: passwordController.text.trim(),
          ),
        ),
      );
    }
  }
}
