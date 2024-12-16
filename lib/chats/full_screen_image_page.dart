import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui'; // For BackdropFilter

class FullScreenImage extends StatelessWidget {
  final String? imageUrl;  // Nullable String

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // Use a fallback URL or asset if imageUrl is null
    final String imageToShow = (imageUrl != null && imageUrl!.isNotEmpty) 
      ? imageUrl! // Ensure imageUrl is not null or empty
      : 'assets/default_profile.jpg';  // Fallback to the default image

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Display the previous screen's background content in the Stack
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.2), // Optional, add a subtle tint to the background
            ),
          ),
          // Background with blur effect (applied only to the portion behind the image)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Apply blur effect
            child: Container(
              color: Colors.black.withOpacity(0.5), // Apply some opacity to the blur background
            ),
          ),
          // Centered image container with margins around it
          Center(
            child: Container(
              margin: const EdgeInsets.all(20.0), // Add margin to leave space around the image
              decoration: BoxDecoration(
                color: Colors.black, // Background color for the image container
                borderRadius: BorderRadius.circular(20.0), // Rounded corners
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0), // Keep rounded corners on the image
                child: imageToShow.contains('assets')
                    ? Image.asset(imageToShow, fit: BoxFit.contain) // Display local asset image
                    : CachedNetworkImage(
                        imageUrl: imageToShow,
                        fit: BoxFit.contain, // Ensure the image fits within the available space
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
              ),
            ),
          ),
          // X icon to close the image and navigate back to the previous screen
          Positioned(
            top: 40.0, // Position the X icon at the top-left corner
            right: 20.0, // Adjust the distance from the right edge
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Go back to the previous screen (chats screen)
              },
              child: const Icon(
                Icons.close,
                color: Colors.white, // Set the color of the "X" icon
                size: 40.0, // Set the size of the "X" icon
              ),
            ),
          ),
        ],
      ),
    );
  }
}
