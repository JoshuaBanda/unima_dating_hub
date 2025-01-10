import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'api_service.dart'; // Import the ApiService
import 'post/post.dart';
import 'comment_dialog.dart';
import 'package:unima_dating_hub/chats/full_screen_image_page.dart';
import 'package:unima_dating_hub/chats/profile_page.dart';
import 'report_page.dart';
import 'post_photo_full_page.dart';
import 'like_button.dart'; // Import the LikeButton widget

class PostItem extends StatefulWidget {
  final Post post;
  final int currentUserId;
  final String currentEmail;
  final String jwtToken;

  PostItem({
    required this.post,
    required this.currentUserId,
    required this.currentEmail,
    required this.jwtToken,
  });

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  int likeCount = 0; // Variable to hold the like count
  bool isLiked =
      false; // Variable to track if the current user has liked the post

  final ApiService apiService =
      ApiService(); // Assuming ApiService is responsible for network calls

  // Method to fetch like count and status for the current post
  void _fetchLikeData() async {
    try {
      // Fetch the like count from the API
      final fetchedLikeCount = await apiService.fetchLikesForPost(
        jwtToken: widget.jwtToken,
        postId: widget.post.postId,
      );

      // Fetch the like status for the current user
      final fetchedIsLiked = await apiService.isUserLikedPost(
        jwtToken: widget.jwtToken,
        postId: widget.post.postId,
        userId: widget.currentUserId,
      );

      setState(() {
        likeCount = fetchedLikeCount;
        isLiked = fetchedIsLiked;
      });
      print("like count $likeCount   is liked $isLiked");

    } catch (e) {
      print("Error fetching like data: $e");
      // Show error message to the user
      _showErrorMessage("Failed to load like data. Please try again.");
    }
  }

  // Display a snackbar for error handling
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLikeData(); // Fetch the like data when the widget is initialized
  }

  // Format the date and time to a readable string in 12-hour format with a 2-hour adjustment
  String _formatDate(DateTime date) {
    final adjustedDate = date.add(Duration(hours: 2));
    return DateFormat('dd/MM/yyyy hh:mm a').format(adjustedDate);
  }

  void _onProfilePicturePressed(String profileImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(
          imageUrl: profileImage.isNotEmpty
              ? profileImage
              : 'assets/default_profile.png',
        ),
      ),
    );
  }

  void _onUsernamePressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          profilePicture: widget.post.profilePicture.isNotEmpty
              ? widget.post.profilePicture
              : 'assets/default_profile.png',
          firstName: widget.post.username.split(' ')[0],
          lastName: widget.post.username.split(' ').length > 1
              ? widget.post.username.split(' ')[1]
              : '',
          currentUserId: widget.currentUserId.toString(),
          secondUserId: widget.post.userId.toString(),
          jwtToken: widget.jwtToken,
        ),
      ),
    );
  }

  void _reportPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(
          postId: widget.post.postId,
          currentUserId: widget.currentUserId,
          secondUserId: widget.post.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String profileImage = widget.post.profilePicture;
    bool isValidUrl = profileImage.startsWith('http://') ||
        profileImage.startsWith('https://');
    if (!isValidUrl) {
      profileImage = 'assets/default_profile.png';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _onProfilePicturePressed(profileImage),
                child: CircleAvatar(
                  backgroundImage: isValidUrl
                      ? CachedNetworkImageProvider(profileImage)
                      : AssetImage(profileImage) as ImageProvider,
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: _onUsernamePressed,
                child: Text(
                  widget.post.username,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'report') {
                    _reportPost();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Report Post'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            "Posted on: ${_formatDate(widget.post.createdAt)}",
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostPhotoFullPage(
                  imageUrl: widget.post.photoUrl,
                  postDescription: widget.post.description,
                  isLiked: isLiked,
                  postId: widget.post.postId,
                  currentUserId: widget.currentUserId,
                  currentEmail: widget.currentEmail,
                  jwtToken: widget.jwtToken,
                ),
              ),
            );
          },
          child: ClipRRect(
            child: CachedNetworkImage(
              imageUrl: widget.post.photoUrl,
              cacheManager: CacheManager(
                Config(
                  'customCacheKey',
                  stalePeriod: Duration(days: 7),
                  maxNrOfCacheObjects: 100,
                ),
              ),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              placeholder: (context, url) => Center(
                  child: SpinKitFadingCircle(color: Colors.grey, size: 50.0)),
              errorWidget: (context, url, error) =>
                  Center(child: Icon(Icons.error)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pass the actual like count and isLiked status to the LikeButton
              LikeButton(
                postId: widget.post.postId,
                userId: widget.currentUserId,
                jwtToken: widget.jwtToken,
                initialLikeCount: likeCount, // Pass the actual like count
                initialLikeStatus:
                    isLiked, // Pass whether the current user has liked the post
              ),
              IconButton(
                icon: Icon(
                  Icons.comment,
                  color: Colors.redAccent,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CommentDialog(
                      postId: widget.post.postId,
                      currentUserId: widget.currentUserId,
                      currentEmail: widget.currentEmail,
                      jwtToken: widget.jwtToken,
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
