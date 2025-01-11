import 'package:flutter/material.dart';
import 'confession_list.dart';
import 'create_confession_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnonymousConfessionPage extends StatelessWidget {
  final String jwtToken;
  final int currentUserId;
  final String currentEmail;

  const AnonymousConfessionPage({
    Key? key,
    required this.jwtToken,
    required this.currentUserId,
    required this.currentEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink, Colors.blue], // Example gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 25), // Space for the top icon
            // Column to contain the icon and the text "Confess"
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Centering the items horizontally
              children: [
                // Icon to create confession
                IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.masksTheater, // Theatrical mask icon
                    size: 40.0,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Navigate to the confession creation page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateConfessionPage(userId: currentUserId.toString()),
                      ),
                    );
                  },
                ),
                // Text under the icon
                Text(
                  'Confess',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            // Widget to display a list of anonymous Confessions
            Expanded(
              child: ConfessionListPage(
                currentUserId: currentUserId,
                currentEmail: currentEmail,
                jwtToken: jwtToken,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
