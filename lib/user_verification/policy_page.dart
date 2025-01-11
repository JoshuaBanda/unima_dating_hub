import 'package:flutter/material.dart';
import 'sign_up.dart';

class PolicyPage extends StatefulWidget {
  const PolicyPage({Key? key}) : super(key: key);

  @override
  _PolicyPageState createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  bool _isAccepted = false; // Track the checkbox state

  @override
  Widget build(BuildContext context) {
    // Container style
    final containerStyle = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
    );

    // Text styles
    final headingStyle = TextStyle(
      fontSize: 24,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    final subheadingStyle = TextStyle(
      fontSize: 20,
      color: Colors.green,
      fontWeight: FontWeight.bold,
    );

    final paragraphStyle = TextStyle(
      fontSize: 16,
      color: Colors.grey[800],
      height: 1.6,
    );

    final listStyle = TextStyle(
      fontSize: 16,
      color: Colors.grey[800],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unima Dating Hub User Policy'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: containerStyle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Unima Dating Hub User Policy", style: headingStyle, textAlign: TextAlign.center),
                const SizedBox(height: 40),
                
                // Eligibility Section
                _buildSection(
                  "1. Eligibility",
                  "To use Unima Dating Hub, users must meet the following criteria:",
                  [
                    "Age: You must be at least 18 years of age or older to use this platform.",
                    "Student Status: Users must be currently enrolled in an accredited educational institution (e.g., college, university, or similar educational body). You will be required to verify your student status to create an account."
                  ],
                  subheadingStyle,
                  paragraphStyle,
                  listStyle,
                ),
                
                // Account Creation Section
                _buildSection(
                  "2. Account Creation",
                  "When creating an account, you must provide accurate, truthful, and up-to-date information. The following is required:",
                  [
                    "Email Address (preferably a school email address for verification).",
                  ],
                  subheadingStyle,
                  paragraphStyle,
                  listStyle,
                ),

                // Privacy and Data Protection Section
                _buildSection(
                  "3. Privacy and Data Protection",
                  "Your privacy is of utmost importance to us. The information you provide, including personal details, profile data, and communication, will be handled as follows:",
                  [
                    "Data Collection: We collect personal information that you provide voluntarily, including your name, email address, age, location, student status, profile picture, and any content you share (e.g., photos, messages).",
                    "Data Usage: Your data is used to verify your eligibility as a student, personalize your experience on the app, facilitate connections with other users, and send notifications or updates relevant to your account.",
                    "Data Sharing: We do not sell or share your personal information with third parties, except as required by law or to enforce our terms of service.",
                    "Data Security: We use industry-standard security measures to protect your data, including encryption and secure servers."
                  ],
                  subheadingStyle,
                  paragraphStyle,
                  listStyle,
                ),
                
                // User Behavior and Conduct Section
                _buildSection(
                  "4. User Behavior and Conduct",
                  "By using this app, you agree to:",
                  [
                    "Respect Other Users: Be courteous, respectful, and considerate when interacting with other users.",
                    "Prohibited Content: You may not upload, share, or post any content that is offensive, abusive, or discriminatory.",
                    "No Solicitations: Users are prohibited from using the platform for business transactions, solicitations, or advertising."
                  ],
                  subheadingStyle,
                  paragraphStyle,
                  listStyle,
                ),

                // Safety and Reporting Section
                _buildSection(
                  "5. Safety and Reporting",
                  "We are committed to providing a safe environment for all users. If you encounter any suspicious or inappropriate behavior, we encourage you to report it immediately.",
                  [
                    "Reporting Mechanism: If you experience harassment, receive inappropriate messages, or encounter any user who violates the terms of service, please report them through the app’s reporting feature.",
                    "Blocking Users: You have the ability to block any user who makes you feel uncomfortable. Blocking a user prevents them from sending messages or viewing your profile."
                  ],
                  subheadingStyle,
                  paragraphStyle,
                  listStyle,
                ),

                // Accept Policy Checkbox and Button
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _isAccepted,
                      onChanged: (bool? value) {
                        setState(() {
                          _isAccepted = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "I accept the terms and conditions.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

                // Accept Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAccepted
                        ? () {
                            // Navigate to sign-in page after accepting the policy
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Accept and Continue", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create sections dynamically
  Widget _buildSection(String title, String description, List<String> listItems, TextStyle subheadingStyle, TextStyle paragraphStyle, TextStyle listStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: subheadingStyle),
          const SizedBox(height: 10),
          Text(description, style: paragraphStyle),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listItems.map((item) => Text("• $item", style: listStyle)).toList(),
          ),
        ],
      ),
    );
  }
}
