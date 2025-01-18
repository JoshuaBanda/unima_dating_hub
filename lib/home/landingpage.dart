import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '/user_verification/Login_SignUp.dart'; // Make sure to import the LoginPage

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Grid view for images
          GridView.custom(
            gridDelegate: SliverQuiltedGridDelegate(
              crossAxisCount: 4, // Number of columns in the grid
              mainAxisSpacing: 4, // Vertical space between grid items
              crossAxisSpacing: 4, // Horizontal space between grid items
              repeatPattern: QuiltedGridRepeatPattern.inverted, // Inverted pattern
              pattern: [
                QuiltedGridTile(2, 2), // Tile spans 2x2 (2 columns, 2 rows)
                QuiltedGridTile(1, 1), // Tile spans 1x1 (1 column, 1 row)
                QuiltedGridTile(1, 1), // Tile spans 1x1 (1 column, 1 row)
                QuiltedGridTile(1, 2), // Tile spans 1x2 (1 column, 2 rows)
              ],
            ),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, index) => Tile(index: index), // Your custom Tile widget
            ),
          ),

          // Black transparent background with text
          Positioned.fill(
            child: Container(
              color: Color.fromARGB(90, 0, 0, 0), // Semi-transparent black background
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    'WELCOME TO UNIMA DATING HUB',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Positioned Continue Button
          Positioned(
            bottom: 30.0,
            left: 20.0,
            right: 20.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 214, 53, 25), // Button color
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
              ),
              onPressed: () {
                // Navigate to LoginPage when pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tile widget that displays images based on the index
class Tile extends StatelessWidget {
  final int index;

  const Tile({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the image path based on the index
    String imagePath = _getImagePath(index);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10), // Rounded corners for images
      child: Image.asset(
        imagePath, // Image based on index
        fit: BoxFit.cover, // Makes sure the image fills the tile area
      ),
    );
  }

  // Helper function to get image path based on the index
  String _getImagePath(int index) {
    switch (index) {
      case 0:
        return 'assets/image7.jpg'; // Replace with your image path
      case 1:
        return 'assets/image2.jpg'; // Replace with your image path
      case 2:
        return 'assets/love3.jpg'; // Replace with your image path
      case 3:
        return 'assets/couple.jpg'; // Replace with your image path
      case 4:
        return 'assets/love2.jpg'; // Replace with your image path
      case 5:
        return 'assets/love3.jpg'; // Replace with your image path
      case 6:
        return 'assets/love1.jpg'; // Replace with your image path
      case 7:
        return 'assets/image6.jpg'; // Replace with your image path
      case 8:
        return 'assets/love2.jpg'; // Replace with your image path
      case 9:
        return 'assets/image6.jpg'; // Replace with your image path
      case 10:
        return 'assets/image2.jpg'; // Replace with your image path
      case 11:
        return 'assets/love5.jpg'; // Replace with your image path
      case 12:
        return 'assets/image2.jpg'; // Replace with your image path
      case 13:
        return 'assets/love1.jpg'; // Replace with your image path
      case 14:
        return 'assets/love5.jpg'; // Replace with your image path
      case 15:
        return 'assets/love3.jpg'; // Replace with your image path
      case 16:
        return 'assets/love2.jpg'; // Replace with your image path
      case 17:
        return 'assets/love1.jpg'; // Replace with your image path
      default:
        return 'assets/image2.jpg'; // Default image if index doesn't match
    }
  }
}
