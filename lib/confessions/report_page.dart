import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportPage extends StatefulWidget {
  final int confessionId;
  final int currentUserId;
  final int secondUserId;

  ReportPage({
    required this.confessionId,
    required this.currentUserId,
    required this.secondUserId,
  });

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _reportController = TextEditingController();
  bool isSubmitting = false;

  // Function to send the report to the backend
  Future<void> _sendReport() async {
    setState(() {
      isSubmitting = true;
    });

    String reportMessage = _reportController.text.trim();

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
      final response = await http.post(
        Uri.parse('https://your-backend-api.com/report'), // Replace with your actual API URL
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'confessionId': widget.confessionId,
          'currentUserId': widget.currentUserId,
          'secondUserId': widget.secondUserId,
          'reportMessage': reportMessage,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Confession has been reported successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to report the confession. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
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
        title: Text('Report Confession'),
        backgroundColor: Colors.red, // Red theme color for the AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                // Handle selection
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
                ? Center(child: CircularProgressIndicator()) // Show loading indicator while submitting
                : ElevatedButton(
                    onPressed: _sendReport, // Submit the report
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Red background color for the button
                      iconColor: Colors.white, // White text color
                    ),
                    child: Text(
                      'Report Confession',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
            SizedBox(height: 8),
            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red), // Red color for cancel text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
