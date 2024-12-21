import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MyProfilePage extends StatefulWidget {
  final String currentUserId;
  final String currentUserEmail;
  final String firstName;  // Add firstName
  final String lastName;   // Add lastName
  final String profilePicture; // Add profilePicture
  final bool activationStatus; // Add activationStatus

  const MyProfilePage({
    super.key,
    required this.currentUserId,
    required this.currentUserEmail,
    required this.firstName,  // Expect firstName in the constructor
    required this.lastName,   // Expect lastName in the constructor
    required this.profilePicture, // Expect profilePicture in the constructor
    required this.activationStatus, // Expect activationStatus in the constructor
  });

  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String profilePictureUrl = '';
  File? _imageFile;
  bool _isSubmitting = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getProfileData();
  }

  // Fetch user profile data using the current user ID
  Future<void> _getProfileData() async {
    try {
      final response = await http.get(
        Uri.parse('https://datehubbackend.onrender.com/users/${widget.currentUserId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profilePictureUrl = data['profilepicture'] ?? 'default_image_url';
          _firstNameController.text = data['firstname'];
          _lastNameController.text = data['lastname'];
        });
      } else {
        _showError('Failed to load profile data');
      }
    } catch (e) {
      _showError('An error occurred while fetching profile data');
    }
  }

  // Show error messages in a SnackBar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Pick an image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Update the profile field (first name/last name)
  Future<void> _updateProfileField(String url, String fieldName, String fieldValue) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.currentUserEmail,
          fieldName: fieldValue,
        }),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$fieldName updated successfully')));
        _getProfileData(); // Reload profile after update
      } else {
        _showError('Failed to update $fieldName');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showError('An error occurred: $e');
    }
  }

  // Update the profile picture
  Future<void> _updateProfilePicture() async {
    if (_imageFile == null) return; // No image selected

    setState(() {
      _isSubmitting = true;
    });

    final uri = Uri.parse('https://datehubbackend.onrender.com/cloudinary/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['email'] = widget.currentUserEmail; // Add the email field

    try {
      // Check if the image file exists before uploading
      if (await _imageFile!.exists()) {
        var file = await http.MultipartFile.fromPath('file', _imageFile!.path);
        request.files.add(file);

        var response = await request.send();

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully')));
          _getProfileData(); // Reload profile after picture update
        } else {
          _showError('Failed to update profile picture');
        }
      } else {
        _showError('Image file does not exist.');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 100,
                      backgroundImage: _imageFile == null
                          ? NetworkImage(profilePictureUrl)
                          : FileImage(_imageFile!) as ImageProvider,
                      child: _imageFile == null
                          ? const Icon(Icons.add_a_photo, size: 30, color: Colors.white)
                          : null,
                    ),
                    if (_imageFile != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.save, color: Colors.green, size: 28),
                          onPressed: _isSubmitting ? null : _updateProfilePicture,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField('First Name', _firstNameController, 'firstname'),
              const SizedBox(height: 16),
              _buildTextField('Last Name', _lastNameController, 'lastname'),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build text fields
  Widget _buildTextField(String label, TextEditingController controller, String fieldName) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            validator: (value) => value!.isEmpty ? 'Please enter your $label' : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _isSubmitting
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    if (fieldName == 'firstname') {
                      _updateProfileField('https://datehubbackend.onrender.com/users/updatefirstname', fieldName, controller.text);
                    } else if (fieldName == 'lastname') {
                      _updateProfileField('https://datehubbackend.onrender.com/users/updatelastname', fieldName, controller.text);
                    }
                  }
                },
        ),
      ],
    );
  }
}