import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import SpinKit
import 'dart:convert';  // To decode the response

class CreatePostPage extends StatefulWidget {
  final String userId;  // Expecting userId to be passed as String

  const CreatePostPage({Key? key, required this.userId}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool isLoading = false; // Track loading state

  // Pick an image from gallery or camera
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  // Function to send post data to backend
  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image.')),
        );
        return;
      }

      setState(() {
        isLoading = true; // Start loading
      });

      // Get the description (use whitespace if empty)
      final description = _descriptionController.text.isEmpty ? ' ' : _descriptionController.text;
      final photoPath = _selectedImage!.path;


      // Prepare the multipart request
      final uri = Uri.parse('https://datehubbackend.onrender.com/post/create');  // Replace with your API endpoint
      var request = http.MultipartRequest('POST', uri);

      // Add user_id and description field (case-sensitive)
      request.fields['user_id'] = widget.userId; // Pass user_id here (case-sensitive)
      request.fields['description'] = description; // Pass description (whitespace if empty)

      // Add image file with correct content type
      var imageFile = await http.MultipartFile.fromPath(
        'file',  // Match field name expected by your server
        photoPath,
        contentType: MediaType('image', 'jpeg'), // Define the correct content type
      );
      request.files.add(imageFile);

      try {
        // Send the request
        var response = await request.send();
        final responseBody = await response.stream.bytesToString();  // Get response body for debugging

        setState(() {
          isLoading = false; // Stop loading
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Parse the response body
          final Map<String, dynamic> responseMap = jsonDecode(responseBody);

          // Show success message with the post details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Post created successfully!')),
          );



          // Reset fields
          setState(() {
            _selectedImage = null; // Reset the image picker after post creation
            _descriptionController.clear(); // Clear the description field
          });

          // Navigate back to the previous screen
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create post. Error: ${response.statusCode} - $responseBody')),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false; // Stop loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(  // Wrap the entire body in a scrollable widget
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
                  hintText: 'Enter a description for your post',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  // Remove the validation that forces the description to be required
                  return null;  // No validation required for the description
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: _selectedImage == null
                      ? const Center(child: Text('Tap to pick an image'))
                      : Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const Center(child: SpinKitCircle(color: Colors.blue))  // Show loading spinner
                  : Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:const [Colors.pink, Colors.red],  // Gradient colors
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextButton(
                        onPressed: _submitPost,
                        child: const Text(
                          'Create Post',
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
