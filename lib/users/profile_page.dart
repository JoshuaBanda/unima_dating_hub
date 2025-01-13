import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MyProfilePage extends StatefulWidget {
  final String currentUserId;
  final String currentUserEmail;
  final String firstName;
  final String lastName;
  final String profilePicture;
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

  bool _showCharacteristics = false;
  bool _showPreferences = false;

  String firstName = '';
  String lastName = '';
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Variables to store the fetched preferences and characteristics
  Map<String, dynamic> _preferences = {};
  Map<String, dynamic> _characteristics = {};

  // Variables for individual preference fields
  int preferredAge = 0;
  String preferredSex = '';
  int preferredHeight = 0;
  String preferredSkinColor = '';
  String preferredHobby = '';
  String preferredLocation = '';
  String preferredProgramOfStudy = '';
  int preferredYearOfStudy = 0;

  String dob = '';
  String sex = '';
  int height = 0;
  String skinColor = '';
  String hobby = '';
  String location = '';
  String programOfStudy = '';
  int yearOfStudy = 0;

  @override
  void initState() {
    super.initState();
    firstName = widget.firstName;
    lastName = widget.lastName;
    profilePictureUrl = widget.profilePicture;
    _firstNameController.text = firstName;
    _lastNameController.text = lastName;

    // Fetch preferences and characteristics on initial load
    _fetchUserPreferences();
    _fetchUserCharacteristics();
  }

  // Fetch User Preferences and store in a variable
  Future<void> _fetchUserPreferences() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://datehubbackend.onrender.com/preferences/${widget.currentUserId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Debugging the response data

        // Decoding individual preferences into variables with proper type handling
        setState(() {
          preferredAge = _parseInt(data['preferred_age']);
          preferredSex = data['preferred_sex'] ?? '';
          preferredHeight = _parseInt(data['preferred_height']);
          preferredSkinColor = data['preferred_skin_color'] ?? '';
          preferredHobby = data['preferred_hobby'] ?? '';
          preferredLocation = data['preferred_location'] ?? '';
          preferredProgramOfStudy = data['preferred_program_of_study'] ?? '';
          preferredYearOfStudy = _parseInt(data['preferred_year_of_study']);
        });
      } else {
        _showError(
            'Failed to load preferences. Status Code: ${response.statusCode}');
        print(
            'Error: Failed to load preferences. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      _showError('An error occurred: $e');
      print('Error: $e');
    }
  }

  int _parseInt(dynamic value) {
    if (value is String) {
      // If the value is a string, try parsing it to an int
      return int.tryParse(value) ?? 0; // Default to 0 if parsing fails
    }
    return value as int? ??
        0; // Return the value as int if already an integer, otherwise default to 0
  }

  Future<void> _fetchUserCharacteristics() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://datehubbackend.onrender.com/user-characteristics/${widget.currentUserId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);


        // Decoding individual characteristics into variables with proper type handling
        setState(() {
          // Now we extract the values from the response and handle them
          dob = data['dob'] ?? '';
          sex = data['sex'] ?? '';
          height = _parseInt(data[
              'height']); // Using _parseInt for converting height to integer
          skinColor = data['skin_color'] ?? '';
          hobby = data['hobby'] ?? '';
          location = data['location'] ?? '';
          programOfStudy = data['program_of_study'] ?? '';
          yearOfStudy = _parseInt(
              data['year_of_study']); // Converting year_of_study to int
        });
        print('$dob');
      } else {
        _showError('Failed to load characteristics');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
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

  void _updateProfilePicture() async {
    if (_imageFile == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final uri =
        Uri.parse('https://datehubbackend.onrender.com/cloudinary/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['email'] = widget.currentUserEmail;

    try {
      if (await _imageFile!.exists()) {
        var file = await http.MultipartFile.fromPath('file', _imageFile!.path);
        request.files.add(file);

        var response = await request.send();
        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            profilePictureUrl = _imageFile!.path;
          });

          await _storage.delete(key: 'profilepicture');
          await _storage.write(key: 'profilepicture', value: profilePictureUrl);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile picture updated successfully')),
          );
        } else {
          _showError('Failed to update profile picture');
        }
      } else {
        _showError('Image file does not exist');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Text fields for editing user details (first name and last name)
  Widget _buildTextField(String label, TextEditingController controller,
      String fieldName, bool isEditing) {
    return Row(
      children: [
        Expanded(
          child: isEditing
              ? TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your $label'
                      : null,
                )
              : Text(controller.text, style: TextStyle(fontSize: 16)),
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

  Future<void> _updateProfileField(
      String url, String fieldName, String fieldValue) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json
            .encode({'email': widget.currentUserEmail, fieldName: fieldValue}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storage.delete(key: fieldName);
        await _storage.write(key: fieldName, value: fieldValue);

        setState(() {
          if (fieldName == 'firstname') {
            firstName = fieldValue;
          } else if (fieldName == 'lastname') {
            lastName = fieldValue;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fieldName updated successfully')));
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
      child: ListView(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 100,
              backgroundImage: _imageFile == null
                  ? NetworkImage(profilePictureUrl)
                  : FileImage(_imageFile!) as ImageProvider,
              child: _isSubmitting
                  ? CircularProgressIndicator(color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField('First Name', _firstNameController,
                    'firstname', _isEditingFirstName),
                const SizedBox(height: 16),
                _buildTextField('Last Name', _lastNameController, 'lastname',
                    _isEditingLastName),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text("User Characteristics",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  trailing: Icon(_showCharacteristics
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onTap: () {
                    setState(() {
                      _showCharacteristics = !_showCharacteristics;
                    });
                  },
                ),
                if (_showCharacteristics)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date of Birth: $dob", style: TextStyle(fontSize: 16)),
                        Text("Sex: $sex", style: TextStyle(fontSize: 16)),
                        Text("Height: $height cm", style: TextStyle(fontSize: 16)),
                        Text("Skin Color: $skinColor", style: TextStyle(fontSize: 16)),
                        Text("Hobby: $hobby", style: TextStyle(fontSize: 16)),
                        Text("Location: $location", style: TextStyle(fontSize: 16)),
                        Text("Program of Study: $programOfStudy", style: TextStyle(fontSize: 16)),
                        Text("Year of Study: $yearOfStudy", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text("User Preferences",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  trailing: Icon(_showPreferences
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onTap: () {
                    setState(() {
                      _showPreferences = !_showPreferences;
                    });
                  },
                ),
                if (_showPreferences)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Preferred Age: $preferredAge", style: TextStyle(fontSize: 16)),
                        Text("Preferred Sex: $preferredSex", style: TextStyle(fontSize: 16)),
                        Text("Preferred Height: $preferredHeight cm", style: TextStyle(fontSize: 16)),
                        Text("Preferred Skin Color: $preferredSkinColor", style: TextStyle(fontSize: 16)),
                        Text("Preferred Hobby: $preferredHobby", style: TextStyle(fontSize: 16)),
                        Text("Preferred Location: $preferredLocation", style: TextStyle(fontSize: 16)),
                        Text("Preferred Program of Study: $preferredProgramOfStudy", style: TextStyle(fontSize: 16)),
                        Text("Preferred Year of Study: $preferredYearOfStudy", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

}
