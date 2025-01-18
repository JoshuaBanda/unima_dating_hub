import 'package:flutter/material.dart';
import 'confession_list.dart';
import 'create_confession_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
            colors: [const Color.fromARGB(227, 253, 243, 242), const Color.fromARGB(159, 255, 255, 255)], // Example gradient
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
                    color: Colors.pink,
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
            "Confess", // The first name and last name
            style: GoogleFonts.indieFlower(
              textStyle: TextStyle(
                color: Colors.pink,
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
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
