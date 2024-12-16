import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

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
    'Sex': ['Male', 'Female', 'Other'],
    'Height': ['< 5 feet', '5 - 6 feet', '6+ feet'],
    'Skin Color': ['Fair', 'Medium', 'Dark'],
    'Hobby': ['Reading', 'Sports', 'Music', 'Traveling'],
    'Location': ['Urban', 'Suburban', 'Rural'],
    'Program of Study': ['Computer Science', 'Business', 'Engineering', 'Arts'],
    'Year of Study': ['Freshman', 'Sophomore', 'Junior', 'Senior'],
  };

  // Function to handle PUT request
  Future<void> _updateField() async {
    if (_formKey.currentState?.validate() ?? false) {
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
          "Update User Field",  // Text to display
          style: GoogleFonts.dancingScript(
            textStyle: TextStyle(
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [const Color.fromARGB(255, 253, 107, 102), Colors.orange],
                ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              fontStyle: FontStyle.italic, // Italic font style
              fontSize: 32,  // Font size set to 32
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

              // Update button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _updateField,
                  child: Text('Update Field',
                  style: TextStyle(color: Colors.white)
                  ,),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,  // Red background color
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
