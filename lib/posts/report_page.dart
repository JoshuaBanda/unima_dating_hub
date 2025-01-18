import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportPage extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final int secondUserId;
  final String jwtToken; // Add this line to accept the JWT token

  ReportPage({
    required this.postId,
    required this.currentUserId,
    required this.secondUserId,
    required this.jwtToken, // Add the jwtToken to the constructor
  });

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _reportController = TextEditingController();
  bool isSubmitting = false;
  String? selectedReason; // To store the selected reason

  // Function to send the report to the backend
  Future<void> _sendReport() async {
    setState(() {
      isSubmitting = true;
    });

    // Combine the reason with the text from the text field
    String reportMessage = '';
    if (selectedReason != null) {
      reportMessage += selectedReason!; // Add the reason from the dropdown
    }
    reportMessage += ' - ' + _reportController.text.trim(); // Add the additional reason

    if (reportMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a reason for reporting.')),
      );
      setState(() {
        isSubmitting = false;
      });
      return;
    }

    try {
      //print("jwt token: ${widget.jwtToken}");
      final response = await http.post(
        Uri.parse(
            'https://datehubbackend.onrender.com/report/create'), // Replace with your actual API URL
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${widget.jwtToken}', // Add JWT token here in the Authorization header
        },
        body: json.encode({
          'postid': widget.postId,
          'offender': widget.secondUserId,
          'reportMessage': reportMessage,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post has been reported successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to report the post. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
      //print("Error occurred: $e"); // Print error details if exception occurs
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Post'),
        backgroundColor: Colors.red, // Red theme color for the AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Wrap the Column inside a SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thank you for using our services. We care about your safety and want to offer you the best service possible.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 10),
              // Dropdown for selecting the reason for reporting
              DropdownButtonFormField<String>(
                value: selectedReason,
                items: [
                  'Nudity or Sexual Content',
                  'Hate Speech or Bullying',
                  'Violence or Harmful Behavior',
                  'Spam or Scams',
                  'Other',
                ].map((String reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value; // Store the selected reason
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Select Reason for Report',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Input field for additional description of the report
              TextField(
                controller: _reportController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your reason here...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
              SizedBox(height: 20),
              // Submit button
              isSubmitting
                  ? Center(
                      child: CircularProgressIndicator()) // Show loading indicator while submitting
                  : ElevatedButton(
                      onPressed: _sendReport, // Submit the report
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red, // Red background color for the button
                        iconColor: Colors.white, // White text color
                      ),
                      child: Text(
                        'Report Post',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
              SizedBox(height: 8),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style:
                      TextStyle(color: Colors.red), // Red color for cancel text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
