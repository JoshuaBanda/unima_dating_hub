import 'package:flutter/material.dart';
import 'api_service.dart'; // Ensure this is properly importing your ApiService class

class LikeButton extends StatefulWidget {
  final int postId;
  final int userId;
  final String jwtToken;
  final int initialLikeCount; // Initial like count
  final bool initialLikeStatus; // Initial like status (liked or not)

  const LikeButton({
    required this.postId,
    required this.userId,
    required this.jwtToken,
    required this.initialLikeCount,
    required this.initialLikeStatus, // Accept initial like status
  });

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool isLiked = false;
  int likeCount = 0;
  bool isLoading = false; // To show loading indicator

  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Initialize like count and like status from passed parameters
    likeCount = widget.initialLikeCount;
    isLiked = widget.initialLikeStatus;

    // Fetch real like data from the API
    _fetchLikeData();
  }

  // Method to fetch like data from the API
  void _fetchLikeData() async {
    try {
      setState(() {
        isLoading = true; // Start loading
      });

      // Fetch the like count from the API
      final fetchedLikeCount = await apiService.fetchLikesForPost(
        jwtToken: widget.jwtToken,
        postId: widget.postId,
      );

      // Fetch the like status for the current user
      final fetchedIsLiked = await apiService.isUserLikedPost(
        jwtToken: widget.jwtToken,
        postId: widget.postId,
        userId: widget.userId,
      );

      setState(() {
        likeCount = fetchedLikeCount;  // Update the like count with fetched value
        isLiked = fetchedIsLiked;  // Update the like status with fetched value
        isLoading = false;  // Stop loading
      });

      print("Like count: $likeCount, Is liked: $isLiked");

    } catch (e) {
      setState(() {
        isLoading = false;  // Stop loading
      });
      print("Error fetching like data: $e");
      // Show error message to the user
      _showErrorSnackbar("Failed to load like data. Please try again.");
    }
  }

  // Toggle like/unlike the post
  void _toggleLike() async {
    if (isLoading) return; // Prevent multiple presses while loading
    setState(() {
      isLoading = true; // Set loading to true while request is processing
    });

    try {
      if (isLiked) {
        // Attempt to unlike the post
        bool success = await apiService.unlikePost(
          jwtToken: widget.jwtToken,
          postId: widget.postId,
          userId: widget.userId,
        );

        if (success) {
          setState(() {
            isLiked = false;
            likeCount--;
          });
        } else {
          _showErrorSnackbar('Failed to unlike the post');
        }
      } else {
        // Attempt to like the post
        bool success = await apiService.likePost(
          jwtToken: widget.jwtToken,
          postId: widget.postId,
          userId: widget.userId,
        );

        if (success) {
          setState(() {
            isLiked = true;
            likeCount++;
          });
        } else {
          _showErrorSnackbar('Failed to like the post');
        }
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred while processing your request');
    } finally {
      setState(() {
        isLoading = false; // Reset loading state
      });
    }
  }

  // Show error Snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Using a Stack to overlay the loading spinner on top of the button
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.thumb_up,
                color: isLiked ? Colors.redAccent : Colors.grey,
              ),
              onPressed: isLoading ? null : _toggleLike, // Disable button while loading
            ),
            if (isLoading)
              Positioned.fill(
                child: Center(child: CircularProgressIndicator()), // Show loading spinner
              ),
          ],
        ),
        Text(
          '$likeCount', // Display the number of likes
          style: TextStyle(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
