import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // To decode the response

class CreateConfessionPage extends StatefulWidget {
  final String userId; // Expecting userId to be passed as String

  const CreateConfessionPage({Key? key, required this.userId}) : super(key: key);

  @override
  _CreateConfessionPageState createState() => _CreateConfessionPageState();
}

class _CreateConfessionPageState extends State<CreateConfessionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  bool isLoading = false; // Track loading state

  // Function to send confession data to the backend
  Future<void> _submitConfession() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true; // Start loading
      });

      // Get the description (use whitespace if empty)
      final description = _descriptionController.text.isEmpty ? ' ' : _descriptionController.text;

      try {
        // Prepare the request
        final uri = Uri.parse('https://datehubbackend.onrender.com/confession/create'); // Replace with your API endpoint
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': widget.userId, // Pass user_id
            'description': description, // Pass description
          }),
        );

        setState(() {
          isLoading = false; // Stop loading
        });

        if (response.statusCode == 200 || response.statusCode == 201) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Confession created successfully!')),
          );

          // Reset fields
          _descriptionController.clear();

          // Navigate back to the previous screen
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create confession. Error: ${response.statusCode}')),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false; // Stop loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Confession'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter a description for your confession',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const Center(child: CircularProgressIndicator()) // Show loading spinner
                  : Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: const [Colors.pink, Colors.red], // Gradient colors
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextButton(
                        onPressed: _submitConfession,
                        child: const Text(
                          'Create Confession',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
