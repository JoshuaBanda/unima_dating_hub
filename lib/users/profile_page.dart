import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MyProfilePage extends StatefulWidget {
  final String currentUserId;
  final String currentUserEmail;
  String firstName;  // Made mutable (non-final)
  String lastName;   // Made mutable (non-final)
  String profilePicture;
  final bool activationStatus;

  MyProfilePage({
    super.key,
    required this.currentUserId,
    required this.currentUserEmail,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.activationStatus,
  });

  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String profilePictureUrl = '';
  File? _imageFile;
  bool _isSubmitting = false;
  bool _isEditingFirstName = false;
  bool _isEditingLastName = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeProfileData();
  }

  void _initializeProfileData() {
    profilePictureUrl = widget.profilePicture;
    _firstNameController.text = widget.firstName;
    _lastNameController.text = widget.lastName;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _updateProfilePicture();
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _updateProfilePicture();
    }
  }

  Future<void> _updateProfilePicture() async {
    if (_imageFile == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final uri = Uri.parse('https://datehubbackend.onrender.com/cloudinary/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['email'] = widget.currentUserEmail;

    try {
      if (await _imageFile!.exists()) {
        var file = await http.MultipartFile.fromPath('file', _imageFile!.path);
        request.files.add(file);

        var response = await request.send();
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),

          );

          setState(() {
            profilePictureUrl = _imageFile!.path;
          });

          await _storage.delete(key: 'profilepicture');
          await _storage.write(key: 'profilepicture', value: profilePictureUrl);
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storage.delete(key: fieldName);
        await _storage.write(key: fieldName, value: fieldValue);

        setState(() {
          if (fieldName == 'firstname') {
            widget.firstName = fieldValue;  // Update firstName
          } else if (fieldName == 'lastname') {
            widget.lastName = fieldValue;  // Update lastName
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fieldName updated successfully')),
        );
      } else {
        _showError('Failed to update $fieldName');
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
                onTap: _showProfileOptions,
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: _imageFile == null
                      ? NetworkImage(profilePictureUrl)
                      : FileImage(_imageFile!) as ImageProvider,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('First Name', _firstNameController, 'firstname', _isEditingFirstName),
              const SizedBox(height: 16),
              _buildTextField('Last Name', _lastNameController, 'lastname', _isEditingLastName),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProfileOption(Icons.visibility, 'View Profile Picture', _viewProfilePicture),
          _buildProfileOption(Icons.camera_alt, 'Take Photo', _takePhoto),
          _buildProfileOption(Icons.image, 'Choose from Gallery', _pickImage),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _viewProfilePicture() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Profile Picture')),
          body: Center(
            child: Image.network(profilePictureUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String fieldName, bool isEditing) {
    return Row(
      children: [
        Expanded(
          child: isEditing
              ? TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter your $label' : null,
                )
              : Text(
                  controller.text,
                  style: TextStyle(fontSize: 16),
                ),
        ),
        IconButton(
          icon: Icon(isEditing ? Icons.save : Icons.edit),
          onPressed: _isSubmitting
              ? null
              : () {
                  if (isEditing) {
                    if (_formKey.currentState!.validate()) {
                      _updateProfileField(
                        'https://datehubbackend.onrender.com/users/update$fieldName',
                        fieldName,
                        controller.text,
                      );
                      setState(() {
                        if (fieldName == 'firstname') {
                          _isEditingFirstName = false;
                        } else {
                          _isEditingLastName = false;
                        }
                      });
                    }
                  } else {
                    setState(() {
                      if (fieldName == 'firstname') {
                        _isEditingFirstName = true;
                      } else {
                        _isEditingLastName = true;
                      }
                    });
                  }
                },
        ),
      ],
    );
  }
}
