import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import cached_network_image package
import 'comments/comments.dart';
import 'post/post.dart';
import 'comment_dialog.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final int currentUserId;
  final String currentEmail;

  PostItem({
    required this.post,
    required this.currentUserId,
    required this.currentEmail,
  });

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    // Determine the profile picture URL
    String profileImage = widget.post.profilePicture;

    // Check if the profileImage is a valid URL (starts with 'http' or 'https')
    bool isValidUrl = profileImage.startsWith('http://') || profileImage.startsWith('https://');
    
    // If it's not a valid URL, use the fallback local image
    if (!isValidUrl) {
      profileImage = 'assets/default_profile_picture.png'; // Fallback local image
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Profile Picture with caching and URL validation
              CircleAvatar(
                backgroundImage: isValidUrl
                    ? CachedNetworkImageProvider(profileImage) // Use cached network image if URL is valid
                    : AssetImage(profileImage) as ImageProvider, // Fallback to asset image
              ),
              SizedBox(width: 10),
              Text(
                widget.post.username, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            widget.post.description,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
        SizedBox(height: 16),
        ClipRRect(
          child: Image.network(
            widget.post.photoUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 250,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.thumb_up, 
                  color: isLiked ? Colors.deepOrange : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    isLiked = !isLiked;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.comment, 
                  color: Colors.deepOrange,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CommentDialog(
                      postId: widget.post.postId,
                      currentUserId: widget.currentUserId,
                      currentEmail: widget.currentEmail,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Divider(
          thickness: 1,
          color: Colors.grey[300],
        ),
      ],
    );
  }
}
