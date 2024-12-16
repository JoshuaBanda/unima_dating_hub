import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserCharacteristicsPage extends StatefulWidget {
  final String userId;  // Added userId as a parameter to the constructor

  UserCharacteristicsPage({required this.userId}); // Constructor to accept userId

  @override
  _UserCharacteristicsPageState createState() => _UserCharacteristicsPageState();
}

class _UserCharacteristicsPageState extends State<UserCharacteristicsPage> {
  final _formKey = GlobalKey<FormState>();

  // Define controllers for each form field
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _skinColorController = TextEditingController();
  final TextEditingController _hobbyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _programOfStudyController = TextEditingController();
  final TextEditingController _yearOfStudyController = TextEditingController();

  // Date formatting for DOB
  DateTime? _dob;

  // Dropdown for year of study selection
  String? _yearOfStudy;

  // Location and Program of Study selection
  String? _location;
  String? _programOfStudy;
  bool _isOtherLocation = false;

  @override
  void dispose() {
    _dobController.dispose();
    _sexController.dispose();
    _heightController.dispose();
    _skinColorController.dispose();
    _hobbyController.dispose();
    _locationController.dispose();
    _programOfStudyController.dispose();
    _yearOfStudyController.dispose();
    super.dispose();
  }

  // Function to send data to the backend
  Future<void> _sendDataToBackend(Map<String, dynamic> userCharacteristics) async {
    const String apiUrl = 'https://datehubbackend.onrender.com/user-characteristics/create'; // Replace with your backend API URL

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(userCharacteristics),
      );

      if (response.statusCode == 200||response.statusCode == 201) {
        // Successfully sent data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User Characteristics saved successfully!')),
        );
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Function to handle form submission
  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Gather all the data from the form
      final userCharacteristics = {
        'user_id': widget.userId, // Include the userId from the widget
        'dob': _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
        'sex': _sexController.text,
        'height': int.parse(_heightController.text),
        'skin_color': _skinColorController.text,
        'hobby': _hobbyController.text,
        'location': _isOtherLocation ? _locationController.text : _location,
        'program_of_study': _programOfStudy,
        'year_of_study': _yearOfStudy,
      };

      // Send data to backend
      _sendDataToBackend(userCharacteristics);
    }
  }

  // Date Picker for DOB
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(_dob!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Set AppBar color to red
        title: Text(
          "UNIMA DATES",  // Text to display
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Date of Birth (DOB)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      hintText: 'yyyy-MM-dd',
                      suffixIcon: Icon(Icons.calendar_today),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your date of birth';
                      }
                      return null;
                    },
                  ),
                ),

                // Sex (Dropdown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _sexController.text.isNotEmpty ? _sexController.text : null,
                    onChanged: (value) {
                      setState(() {
                        _sexController.text = value ?? '';
                      });
                    },
                    items: [
                      DropdownMenuItem(child: Text("Male"), value: "Male"),
                      DropdownMenuItem(child: Text("Female"), value: "Female"),
                      DropdownMenuItem(child: Text("Other"), value: "Other"),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Sex',
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
                        return 'Please select your sex';
                      }
                      return null;
                    },
                  ),
                ),

                // Height
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
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
                        return 'Please enter your height';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Height must be a valid number';
                      }
                      return null;
                    },
                  ),
                ),

                // Skin Color (Dropdown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _skinColorController.text.isNotEmpty ? _skinColorController.text : null,
                    onChanged: (value) {
                      setState(() {
                        _skinColorController.text = value ?? '';
                      });
                    },
                    items: [
                      DropdownMenuItem(child: Text("Light"), value: "Light"),
                      DropdownMenuItem(child: Text("Medium"), value: "Medium"),
                      DropdownMenuItem(child: Text("Dark"), value: "Dark"),
                      DropdownMenuItem(child: Text("Other"), value: "Other"),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Skin Color',
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
                        return 'Please select your skin color';
                      }
                      return null;
                    },
                  ),
                ),

                // Hobby (Dropdown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _hobbyController.text.isNotEmpty ? _hobbyController.text : null,
                    onChanged: (value) {
                      setState(() {
                        _hobbyController.text = value ?? '';
                      });
                    },
                    items: [
                      DropdownMenuItem(child: Text("Reading"), value: "Reading"),
                      DropdownMenuItem(child: Text("Sports"), value: "Sports"),
                      DropdownMenuItem(child: Text("Music"), value: "Music"),
                      DropdownMenuItem(child: Text("Travelling"), value: "Travelling"),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Hobby',
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
                        return 'Please select your hobby';
                      }
                      return null;
                    },
                  ),
                ),

                // Location (Campus, Chikand, Others)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _location,
                    onChanged: (value) {
                      setState(() {
                        _location = value;
                        _isOtherLocation = value == 'Others'; // If 'Others' is selected
                      });
                    },
                    items: [
                      DropdownMenuItem(child: Text("Campus"), value: "Campus"),
                      DropdownMenuItem(child: Text("Chikand"), value: "Chikand"),
                      DropdownMenuItem(child: Text("Others"), value: "Others"),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Location',
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
                        return 'Please select your location';
                      }
                      return null;
                    },
                  ),
                ),

                // Custom input for Location if 'Others' is selected
                if (_isOtherLocation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Enter Location (If Others)',
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
                          return 'Please enter a location if you selected Others';
                        }
                        return null;
                      },
                    ),
                  ),

                // Program of Study (Dropdown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _programOfStudy,
                    onChanged: (value) {
                      setState(() {
                        _programOfStudy = value;
                      });
                    },
                    items: [
                    DropdownMenuItem(child: Text("Information Systems"), value: "Bachelor of Science in Information Systems"),
                    DropdownMenuItem(child: Text("Computer Science"), value: "Computer Science"),
                    DropdownMenuItem(child: Text("Bsc Generic"), value: "Bachelor of Science Generic"),
                    DropdownMenuItem(child: Text("Biology"), value: "Bachelor of Science in Biology"),
                    DropdownMenuItem(child: Text("Com Net"), value: "Bachelor of Science in Computer Networking Engineering"),
                    DropdownMenuItem(child: Text("Early Childhood Development"), value: "Bachelor of Science in Early Childhood Development"),
                    DropdownMenuItem(child: Text("Electronics"), value: "Bachelor of Science in Electronics"),
                    DropdownMenuItem(child: Text("Mathematics"), value: "Bachelor of Science in Mathematics"),
                    DropdownMenuItem(child: Text("Physics"), value: "Bachelor of Science in Physics"),
                    DropdownMenuItem(child: Text("Statistics"), value: "Bachelor of Science in Statistics"),
                    DropdownMenuItem(child: Text("Geography"), value: "Bachelor of Science in Geography"),
                    DropdownMenuItem(child: Text("Geology"), value: "Bachelor of Science in Geology"),
                    DropdownMenuItem(child: Text("Food and Nutrition"), value: "Bachelor of Science in Food and Nutrition"),
                    DropdownMenuItem(child: Text("Consumer Science"), value: "Bachelor of Science in Consumer Science"),
                    DropdownMenuItem(child: Text("Actuarial Science"), value: "Bachelor of Science in Actuarial Science"),
                    DropdownMenuItem(child: Text("Diploma in Statistics"), value: "Diploma in Statistics"),
                    DropdownMenuItem(child: Text("Education in Biology Science"), value: "Bachelor of Education in Biology Science"),
                    DropdownMenuItem(child: Text("Education in Chemistry"), value: "Bachelor of Education in Chemistry"),
                    DropdownMenuItem(child: Text("Education in Computer Science"), value: "Bachelor of Education in Computer Science"),
                    DropdownMenuItem(child: Text("Education in Ecology"), value: "Bachelor of Education in Ecology"),
                    DropdownMenuItem(child: Text("Education in Language"), value: "Bachelor of Education in Language"),
                    DropdownMenuItem(child: Text("Education in Mathematics"), value: "Bachelor of Education in Mathematics"),
                    DropdownMenuItem(child: Text("Education in Physics"), value: "Bachelor of Education in Physics"),
                    DropdownMenuItem(child: Text("Education in Social Studies"), value: "Bachelor of Education in Social Studies"),
                    DropdownMenuItem(child: Text("Communication and Cultural Studies"), value: "Bachelor of Humanities in Communication and Cultural Studies"),
                    DropdownMenuItem(child: Text("Humanities"), value: "Bachelor of Humanities in Humanities"),
                    DropdownMenuItem(child: Text("Media for Development"), value: "Bachelor of Humanities in Media for Development"),
                    DropdownMenuItem(child: Text("Theology"), value: "Bachelor of Humanities in Theology"),
                    DropdownMenuItem(child: Text("Bachelor of Law"), value: "Bachelor of Law"),
                    DropdownMenuItem(child: Text("Diploma in Law"), value: "Diploma in Law"),
                    DropdownMenuItem(child: Text("Development Economics"), value: "Bachelor of Arts in Development Economics"),
                    DropdownMenuItem(child: Text("Sociology"), value: "Bachelor of Arts in Sociology"),
                    DropdownMenuItem(child: Text("Psychology"), value: "Bachelor of Arts in Psychology"),
                    DropdownMenuItem(child: Text("Social Economic History"), value: "Bachelor of Arts in Social Economic History"),
                    DropdownMenuItem(child: Text("Gender Studies"), value: "Bachelor of Social Science in Gender Studies"),
                    DropdownMenuItem(child: Text("Social Work"), value: "Bachelor of Social Science in Social Work"),
                    DropdownMenuItem(child: Text("Social Science"), value: "Bachelor of Social Science"),
                    DropdownMenuItem(child: Text("Public Administration"), value: "Bachelor of Arts in Public Administration"),
                    DropdownMenuItem(child: Text("Political Science"), value: "Bachelor of Arts in Political Science"),
                    DropdownMenuItem(child: Text("Human Resource Management"), value: "Bachelor of Arts in Human Resource Management"),
                    DropdownMenuItem(child: Text("Economics"), value: "Bachelor of Arts in Economics"),
                    DropdownMenuItem(child: Text("Law Enforcement"), value: "Bachelor of Social Science in Law Enforcement Management and Leadership"),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Program of Study',
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
                        return 'Please select your program of study';
                      }
                      return null;
                    },
                  ),
                ),

                // Year of Study (Dropdown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _yearOfStudy,
                    onChanged: (value) {
                      setState(() {
                        _yearOfStudy = value;
                      });
                    },
                    items: [
                      DropdownMenuItem(child: Text("Year 1"), value: "1"),
                      DropdownMenuItem(child: Text("Year 2"), value: "2"),
                      DropdownMenuItem(child: Text("Year 3"), value: "3"),
                      DropdownMenuItem(child: Text("Year 4"), value: "4"),
                      DropdownMenuItem(child: Text("Year 5"), value: "5"),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Year of Study',
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
                        return 'Please select your year of study';
                      }
                      return null;
                    },
                  ),
                ),

                // Submit Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Submit',
                  style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      iconColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
