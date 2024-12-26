import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '/home/home.dart'; // Update this import based on your actual home screen import
import 'sign_up.dart'; // Ensure the sign up page is correctly imported
import 'email_input.dart'; // Ensure the forgot password screen is correctly imported

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPasswordVisible = false;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _apiUrl = 'https://datehubbackend.onrender.com/users/login';

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenHeight * 0.05,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: Text(
                    'UNIMA DATING HUB',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 214, 53, 25), // Red color
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Enter email',
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          errorText: _errorMessage.isNotEmpty ? 'Invalid email or password' : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 235, 72, 44), // Red color for the button
                          minimumSize: Size(screenWidth * 0.6, 50),
                        ),
                        child: _isLoading
                            ? const SpinKitFadingCircle(color: Colors.grey, size: 50.0)
                            : const Text('LOG IN', style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Forgot Password Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EnterEmailScreen()), // Navigate to Forgot Password screen
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02), // Extra spacing to ensure visibility

                      // Sign Up Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t have an account? ', style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SignUpPage()), // Navigate to Sign Up screen
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(color: Colors.grey[900]),
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

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': emailController.text.trim(),
            'password': passwordController.text.trim(),
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);

          // Extracting the necessary data from the response
          final String token = responseData['result']['access_token'];
          final String currentUserId = responseData['user']['userid'].toString();
          final String currentUserEmail = responseData['user']['email'];
          final String firstName = responseData['user']['firstname'];
          final String lastName = responseData['user']['lastname'];
          final String profilePicture = responseData['user']['profilepicture'];
          final bool activationStatus = responseData['user']['activationstatus'];

          // Securely store the token, user id, email, first name, last name, profile picture, and activation status
          await _storage.write(key: 'jwt_token', value: token);
          await _storage.write(key: 'email', value: currentUserEmail);
          await _storage.write(key: 'userid', value: currentUserId);
          await _storage.write(key: 'firstname', value: firstName);
          await _storage.write(key: 'lastname', value: lastName);
          await _storage.write(key: 'profilepicture', value: profilePicture);
          await _storage.write(key: 'activationstatus', value: activationStatus.toString());

          // Navigate to the FarmSmartScreen with the necessary data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FarmSmartScreen(),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Invalid email or password';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again later.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
