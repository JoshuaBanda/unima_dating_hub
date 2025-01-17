import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:unima_dating_hub/chats/profile_page.dart';

class SearchPage extends StatefulWidget {
  final String myUserId;
  final String jwtToken;

  // Constructor to receive user ID and JWT token
  SearchPage({required this.myUserId, required this.jwtToken});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = []; // To store the results
  bool _isLoading = false; // For loading state
  String _errorMessage = ''; // To store error message

  // Function to fetch search results
  Future<void> _fetchSearchResults(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = ''; // Reset error message when query is empty
      });
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
      _errorMessage = ''; // Reset error message before fetching data
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://datehubbackend.onrender.com/search/search?name=$query'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> results = responseData['users'];

        setState(() {
          _searchResults = results;
          if (_searchResults.isEmpty) {
            // Set a personalized error message when no results are found
            _errorMessage = '$query not found'; 
          }
        });
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      print('Error fetching search results: $e');
      setState(() {
        _searchResults = [];
        _errorMessage =
            'Error fetching results. Please try again later.'; // Show error message
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  // Function to handle item tap
  void _onItemTap(dynamic user) {
    // Handle the onTap event, e.g., navigate to user profile
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          profilePicture: user['profilepicture'] ?? 'assets/default_profile.png',
          firstName: user['firstname'],
          lastName: user['lastname'],
          currentUserId: widget.myUserId,
          secondUserId: user['userid'].toString(),
          jwtToken: widget.jwtToken, // Pass jwtToken here
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
        backgroundColor: Colors.white, // Set the app bar color
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey, // Set the underline to grey
            height: 1.0,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Styled Search Input Field
            TextField(
              controller: _searchController,
              onChanged: (query) {
                _fetchSearchResults(query); // Trigger search on text change
              },
              decoration: InputDecoration(
                hintText: 'Search users or posts...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200], // Light grey background
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30), // Round the edges more
                  borderSide: BorderSide.none, // Remove the border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey), // Set border color to grey
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey), // Set border color to grey
                ),
              ),
            ),
            SizedBox(height: 16.0),
            
            // Display loading spinner when fetching data
            if (_isLoading)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            
            // Display error message if any
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                ),
              ),
            
            // Display results or simulated user placeholders
            Expanded(
              child: _searchResults.isEmpty
                  ? ListView.builder(
                      itemCount: 5, // Simulate 5 users' cards
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Card(
                            margin: EdgeInsets.zero, // Remove margin to keep flat
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0.0, // Remove elevation
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              title: Container(
                                width: 150,
                                height: 20,
                                color: Colors.grey[300], // Rectangular placeholder
                              ),
                              leading: Container(
                                width: 50.0,
                                height: 50.0,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300], // Circular placeholder
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Card(
                            elevation: 0.0, // No elevation for the search results
                            margin: EdgeInsets.zero, // Remove margin to keep flat
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () {
                                _onItemTap(result);
                              },
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
                              title: Text(
                                '${result['firstname']} ${result['lastname']}',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              leading: result['profilepicture'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        result['profilepicture'],
                                        width: 50.0,
                                        height: 50.0,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(Icons.account_circle,
                                      size: 50, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
