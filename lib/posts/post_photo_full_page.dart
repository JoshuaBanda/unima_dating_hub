import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui'; // For BackdropFilter
import 'comment_dialog.dart'; // Import the CommentDialog
import 'like_button.dart'; // Import the LikeButton

class PostPhotoFullPage extends StatefulWidget {
  final String? imageUrl;
  final String postDescription;
  final bool isLiked;
  final int postId;
  final int currentUserId;
  final String currentEmail;
  final String jwtToken; // Add jwtToken parameter

  const PostPhotoFullPage({
    super.key,
    required this.imageUrl,
    required this.postDescription,
    required this.isLiked,
    required this.postId,
    required this.currentUserId,
    required this.currentEmail,
    required this.jwtToken, // Initialize jwtToken
  });

  @override
  _PostPhotoFullPageState createState() => _PostPhotoFullPageState();
}

class _PostPhotoFullPageState extends State<PostPhotoFullPage> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    // Initializing the like state
    isLiked = widget.isLiked;
  }

  @override
  Widget build(BuildContext context) {
    final String imageToShow = (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
        ? widget.imageUrl!
        : 'assets/default_profile.jpg'; // Fallback to the default image

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Display the background content in the Stack
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
          // Positioned UI for like and comment buttons
          Positioned(
            bottom: 20.0,
            left: 20.0,
            right: 20.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description Text
                Text(
                  widget.postDescription,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10),
                // Like Button - Use the LikeButton widget
                LikeButton(
                  postId: widget.postId,
                  userId: widget.currentUserId,
                  jwtToken: widget.jwtToken,
                  initialLikeCount: 0, // Set an initial like count if necessary
                  initialLikeStatus: widget.isLiked, // Use the current like status
                ),
                SizedBox(height: 10),
                // Comment Button
                IconButton(
                  icon: Icon(
                    Icons.comment,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Open CommentDialog just as in the PostItem widget
                    showDialog(
                      context: context,
                      builder: (context) => CommentDialog(
                        postId: widget.postId,
                        currentUserId: widget.currentUserId,
                        currentEmail: widget.currentEmail,
                        jwtToken: widget.jwtToken, // Pass jwtToken to CommentDialog
                      ),
                    );
                  },
                ),
              ],
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
