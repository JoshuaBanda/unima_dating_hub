import 'package:flutter/material.dart';
import 'request_new_password.dart'; // Import the RequestNewPassword widget

class EnterEmailScreen extends StatefulWidget {
  const EnterEmailScreen({super.key});

  @override
  _EnterEmailScreenState createState() => _EnterEmailScreenState();
}

class _EnterEmailScreenState extends State<EnterEmailScreen> {
  final TextEditingController _emailController = TextEditingController();

  // Function to handle the email input and navigate to the next screen
  void _navigateToRequestNewPassword() {
    String email = _emailController.text;

    // Basic validation for email format
    if (email.isEmpty || !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address")),
      );
    } else {
      // Navigate to RequestNewPassword screen and pass the email
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequestNewPassword(email: email),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center( // Center the content vertically and horizontally
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15), // Added space between text and input field

              // Description of the action
              Text(
                'We will send you a 6-digit code to verify your identity.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30), // Space between description and text field

              // Email TextField with custom styles
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email here',
                  hintStyle: const TextStyle(color: Colors.grey), // Hint text color
                  labelStyle: TextStyle(color: Colors.grey[700]), // Label text color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                    borderSide: BorderSide(color: Colors.red, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey[700]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Padding inside the TextField
                ),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 16), // Font size for the input text
              ),
              const SizedBox(height: 20), // Space between the TextField and button

              // Send OTP Button with custom styles
              ElevatedButton(
                onPressed: _navigateToRequestNewPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor:Colors.red, // Button color
                  minimumSize: const Size(double.infinity, 40), // Full width button with fixed height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded button corners
                  ),
                  elevation: 5, // Button shadow
                ),
                child: const Text(
                  'Verify Identity',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20), // Space below button

              // Friendly reminder text below button
              Text(
                'Make sure to check your inbox for the verification code.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
