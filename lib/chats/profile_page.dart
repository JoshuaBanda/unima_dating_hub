import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/posts/profile_post_list_page.dart'; // Import your ProfilePostListPage widget
import 'messages/contact_message.dart';

class ProfilePage extends StatefulWidget {
  final String profilePicture;
  final String firstName;
  final String lastName;
  final String currentUserId;
  final String secondUserId;
  final String jwtToken;

  const ProfilePage({
    Key? key,
    required this.profilePicture,
    required this.firstName,
    required this.lastName,
    required this.currentUserId,
    required this.secondUserId,
    required this.jwtToken,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool creatingInbox = false;
  bool _showCharacteristics = false;
  bool _isLoading = true;

  // Individual variables for each characteristic (excluding id and user_id)
  String? dob;
  String? sex;
  int? height;
  String? skinColor;
  String? hobby;
  String? location;
  String? programOfStudy;
  int? yearOfStudy;

  @override
  void initState() {
    super.initState();
    print("Fetching user characteristics...");
    _fetchUserCharacteristics();
  }

  Future<void> _fetchUserCharacteristics() async {
    final userId = widget.secondUserId;
    final token = widget.jwtToken;

    try {
      print("Sending request to fetch characteristics for userId: $userId");

      final response = await http.get(
        Uri.parse('https://datehubbackend.onrender.com/user-characteristics/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("Received response with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        setState(() {
          final Map<String, dynamic> characteristics = json.decode(response.body);

          // Decode individual characteristics into variables
          dob = characteristics['dob'];
          sex = characteristics['sex'];
          height = characteristics['height'];
          skinColor = characteristics['skin_color'];
          hobby = characteristics['hobby'];
          location = characteristics['location'];
          programOfStudy = characteristics['program_of_study'];
          yearOfStudy = characteristics['year_of_study'];

          _isLoading = false;
        });
        print("Fetched characteristics: $dob, $sex, $height, $skinColor, $hobby, $location, $programOfStudy, $yearOfStudy");
      } else {
        setState(() {
          _isLoading = false;
        });
        print("Failed to load characteristics, status code: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load characteristics')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching characteristics: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> sendFriendRequest() async {
    setState(() {
      creatingInbox = true;
    });

    final requestData = {
      'firstuserid': int.parse(widget.currentUserId),
      'seconduserid': int.parse(widget.secondUserId),
    };

    print("Sending friend request: $requestData");

    try {
      final response = await http.post(
        Uri.parse(
            'https://datehubbackend.onrender.com/creatingnewconversation/startconva'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print("Friend request response status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          creatingInbox = false;
        });
        final inbox = json.decode(response.body);
        if (inbox.isNotEmpty) {
          print("Friend request successful. Navigating to chat.");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactMessage(
                userId: widget.secondUserId,
                myUserId: widget.currentUserId,
                firstName: widget.firstName,
                lastName: widget.lastName,
                profilePicture: widget.profilePicture,
              ),
            ),
          );
        }
      } else {
        setState(() {
          creatingInbox = false;
        });
        print("Already friends or request failed.");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('You are already friends with ${widget.firstName}')));
      }
    } catch (e) {
      setState(() {
        creatingInbox = false;
      });
      print("Error sending friend request: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void openMessageScreen() async {
    setState(() {
      creatingInbox = true;
    });

    final requestData = {
      'firstuserid': int.parse(widget.currentUserId),
      'seconduserid': int.parse(widget.secondUserId),
    };

    print("Sending message screen request: $requestData");

    try {
      final response = await http.post(
        Uri.parse(
            'https://datehubbackend.onrender.com/creatingnewconversation/startconva'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print("Message screen request response status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 500) {
        setState(() {
          creatingInbox = false;
        });
        final inbox = json.decode(response.body);
        if (inbox.isNotEmpty) {
          print("Message screen opened. Navigating to chat.");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactMessage(
                userId: widget.secondUserId,
                myUserId: widget.currentUserId,
                firstName: widget.firstName,
                lastName: widget.lastName,
                profilePicture: widget.profilePicture,
              ),
            ),
          );
        }
      } else {
        setState(() {
          creatingInbox = false;
        });
        print("Failed to start conversation.");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start conversation')));
      }
    } catch (e) {
      setState(() {
        creatingInbox = false;
      });
      print("Error opening message screen: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentUserId = int.parse(widget.currentUserId);
    int secondUserId = int.parse(widget.secondUserId);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
            child: Column(
              children: [
                Center(
                  child: Text(
                    '${widget.firstName} ${widget.lastName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(widget.profilePicture),
                  ),
                ),
                const SizedBox(height: 20),
                creatingInbox
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGradientButton(
                            text: 'Add Friend',
                            colors: [Colors.blue, Colors.blueAccent],
                            onPressed: sendFriendRequest,
                          ),
                          const SizedBox(width: 16),
                          _buildGradientButton(
                            text: 'Message',
                            colors: [Colors.pink, Colors.red],
                            onPressed: openMessageScreen,
                          ),
                        ],
                      ),
              ],
            ),
          ),
          const Divider(),

          // Add a section for showing characteristics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
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
                    trailing: Icon(
                      _showCharacteristics
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    onTap: () {
                      setState(() {
                        _showCharacteristics = !_showCharacteristics;
                      });
                    },
                  ),
                  if (_showCharacteristics) _buildUserCharacteristics(),
                ],
              ),
            ),
          ),

          Expanded(
            child: ProfilePostListPage(
              currentUserId: currentUserId,
              currentEmail:
                  widget.currentUserId, // Update if email is required here
              secondUserId: secondUserId,
              jwtToken: widget.jwtToken,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for user characteristics
  Widget _buildUserCharacteristics() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dob != null) Text("Date of Birth: $dob"),
          if (sex != null) Text("Sex: $sex"),
          if (height != null) Text("Height: $height cm"),
          if (skinColor != null) Text("Skin Color: $skinColor"),
          if (hobby != null) Text("Hobby: $hobby"),
          if (location != null) Text("Location: $location"),
          if (programOfStudy != null) Text("Program of Study: $programOfStudy"),
          if (yearOfStudy != null) Text("Year of Study: $yearOfStudy"),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
