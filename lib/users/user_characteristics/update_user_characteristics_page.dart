import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'user_characteristics_page.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class UpdateFieldPage extends StatefulWidget {
  final String userId; // Accept user_id as a parameter

  // Constructor to accept user_id
  UpdateFieldPage({required this.userId});

  @override
  _UpdateFieldPageState createState() => _UpdateFieldPageState();
}

class _UpdateFieldPageState extends State<UpdateFieldPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedField;
  String? _selectedValue;
  bool _isLoading = false; // Track loading state

  // List of fields that can be updated
  final List<String> _fields = [
    'Sex',
    'Height',
    'Skin Color',
    'Hobby',
    'Location',
    'Program of Study',
    'Year of Study',
  ];

  // Mapping fields to their possible values
  final Map<String, List<String>> _fieldOptions = {
    'Sex': ['Male', 'Female',],
    'Height': ['100', '150', '200'],
    'Skin Color': ['Light', 'Medium', 'Dark'],
    'Hobby': ['Reading', 'Sports', 'Music', 'Traveling'],
    'Location': ['Campus', 'Chikanda'],
    'Program of Study': ['Information Systems', 'Computer Science', 'Bsc Generic', 'Biology', 'Computer Networking Engineering', 'Early Childhood Development', 'Electronics', 'Mathematics', 'Physics', 'Statistics', 'Geography', 'Geology', 'Food and Nutrition', 'Consumer Science', 'Actuarial Science', 'Diploma in Statistics', 'Education in Biology Science', 'Education in Chemistry', 'Education in Computer Science', 'Education in Ecology', 'Education in Language', 'Education in Mathematics', 'Education in Physics', 'Education in Social Studies', 'Communication and Cultural Studies', 'Humanities', 'Media for Development', 'Theology', 'Law', 'Diploma in Law', 'Development Economics', 'Sociology', 'Psychology', 'Social Economic History', 'Gender Studies', 'Social Work', 'Social Science', 'Public Administration', 'Political Science', 'Human Resource Management', 'Economics', 'Law Enforcement'],
    'Year of Study': ['1', '2', '3', '4', '5'],
  };

  // Function to handle PUT request
  Future<void> _updateField() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      String url = 'https://your-backend-api.com/update'; // Replace with your backend URL
      String selectedField = _selectedField ?? '';
      String updatedValue = _selectedValue ?? '';  // Use the selected value from the dropdown

      // Create the payload for the PUT request
      Map<String, String> payload = {
        'user_id': widget.userId,  // Include user_id from the widget
        'field': selectedField,
        'value': updatedValue,
      };

      // Send PUT request
      try {
        final response = await http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        );

        setState(() {
          _isLoading = false; // Hide loading indicator
        });

        if (response.statusCode == 200) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Field updated successfully!')),
          );
        } else {
          // Error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update field!')),
          );
        }
      } catch (error) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
        // Network or server error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Set AppBar color to red
        title: Text(
          "Change character",  // Text to display
          style: GoogleFonts.raleway(
            textStyle: TextStyle(
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [const Color.fromARGB(255, 253, 107, 102), Colors.orange],
                ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              fontSize: 24,  // Font size set to 32
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown for selecting the field to update
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedField,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedField = newValue;
                      _selectedValue = null;  // Reset the value when field changes
                    });
                  },
                  items: _fields
                      .map((field) => DropdownMenuItem(
                            value: field,
                            child: Text(field),
                          ))
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'Select Field to Update',
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a field';
                    }
                    return null;
                  },
                ),
              ),

              // Dropdown for selecting the value based on the selected field
              if (_selectedField != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedValue = newValue;
                      });
                    },
                    items: _fieldOptions[_selectedField]!
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Select Value',
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a value';
                      }
                      return null;
                    },
                  ),
                ),

              // Loading spinner or Update button
              _isLoading
                  ? Center(child: SpinKitFadingCircle(color: Colors.grey, size: 50.0))
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: _updateField,
                        child: Text(
                          'Update character',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,  // Red background color
                        ),
                      ),
                    ),

              // New option for first time bio setup
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to SetUpBioPage if this button is pressed
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserCharacteristicsPage(userId: widget.userId)),
                    );
                  },
                  child: Text(
                    'First time setting up your bio? Set up now.',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[500],  // Blue background for bio setup button
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
