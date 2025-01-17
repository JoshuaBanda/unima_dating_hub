import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'connfession/confession.dart';
import 'comment_dialog.dart';
import 'package:unima_dating_hub/chats/full_screen_image_page.dart';
import 'report_page.dart';
import 'confession_photo_full_page.dart';
import 'like_button.dart'; // Import the LikeButton widget
import 'api_service.dart'; // Import the ApiService
import 'package:google_fonts/google_fonts.dart';

class ConfessionItem extends StatefulWidget {
  final Confession confession;
  final int currentUserId;
  final String currentEmail;
  final String jwtToken;

  const ConfessionItem({
    Key? key,
    required this.confession,
    required this.currentUserId,
    required this.currentEmail,
    required this.jwtToken,
  }) : super(key: key);

  @override
  _ConfessionItemState createState() => _ConfessionItemState();
}

class _ConfessionItemState extends State<ConfessionItem> {
  bool isLiked = false;
  int likeCount = 0; // Variable to hold the like count
  final ApiService apiService = ApiService();

  // Method to fetch like count and status for the current confession
  void _fetchLikeData() async {
    try {
      // Fetch the like count from the API
      final fetchedLikeCount = await apiService.fetchLikesForConfession(
        jwtToken: widget.jwtToken,
        confessionId: widget.confession.confessionId,
      );

      // Fetch the like status for the current user
      final fetchedIsLiked = await apiService.isUserLikedConfession(
        jwtToken: widget.jwtToken,
        confessionId: widget.confession.confessionId,
        userId: widget.currentUserId,
      );

      setState(() {
        likeCount = fetchedLikeCount;
        isLiked = fetchedIsLiked;
      });
      //print("like count $likeCount   is liked $isLiked");

    } catch (e) {
      //print("Error fetching like data: $e");
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

  String _formatDate(DateTime date) {
    final adjustedDate = date.add(const Duration(hours: 2));
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
    // Implement the user profile navigation if needed
  }

  void _reportConfession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(
          confessionId: widget.confession.confessionId,
          currentUserId: widget.currentUserId,
          secondUserId: widget.confession.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String profileImage = "https://res.cloudinary.com/dfahzd3ky/image/upload/v1734980866/farmsmart/mask.jpg.jpg";
    bool isValidUrl = profileImage.startsWith('http://') || profileImage.startsWith('https://');
    if (!isValidUrl) {
      profileImage = 'assets/default_profile.png';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _onProfilePicturePressed(profileImage),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: isValidUrl
                      ? CachedNetworkImageProvider(profileImage)
                      : AssetImage(profileImage) as ImageProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _onUsernamePressed,
                  child: Text(
                    "Anonymous",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'report') {
                    _reportConfession();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(value: 'report', child: Row(
                    children: const [
                      Icon(Icons.report, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Report Confession'),
                    ],
                  )),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Date Section
          Text(
            "Posted on: ${_formatDate(widget.confession.createdAt)}",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 12),

          // Photo Section
          if (widget.confession.photoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfessionPhotoFullPage(
                        imageUrl: widget.confession.photoUrl,
                        confessionDescription: widget.confession.description,
                        isLiked: isLiked,
                        confessionId: widget.confession.confessionId,
                        currentUserId: widget.currentUserId,
                        currentEmail: widget.currentEmail,
                        jwtToken: widget.jwtToken,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: CachedNetworkImage(
                    imageUrl: widget.confession.photoUrl,
                    cacheManager: CacheManager(
                      Config(
                        'customCacheKey',
                        stalePeriod: const Duration(days: 7),
                        maxNrOfCacheObjects: 100,
                      ),
                    ),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                    placeholder: (context, url) => const Center(
                      child: SpinKitFadingCircle(color: Colors.grey, size: 50.0),
                    ),
                    errorWidget: (context, url, error) =>
                        const Center(child: Icon(Icons.error)),
                  ),
                ),
              ),
            ),

          // Description Section inside Card
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(top: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color.fromARGB(246, 255, 255, 255), const Color.fromARGB(159, 255, 255, 255)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
  widget.confession.description,
  style: GoogleFonts.indieFlower(
    textStyle: TextStyle(
      color: Colors.grey[1000],
      fontSize: 24,
    ),
  ),
),

              ),
            ),
          ),

          // Actions Section (Like and Comment Buttons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LikeButton(
                confessionId: widget.confession.confessionId,
                userId: widget.currentUserId,
                jwtToken: widget.jwtToken,
                initialLikeCount: likeCount,
                initialLikeStatus: isLiked,
              ),
              IconButton(
                icon: const Icon(
                  Icons.comment,
                  color: Colors.redAccent,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CommentDialog(
                      confessionId: widget.confession.confessionId,
                      currentUserId: widget.currentUserId,
                      currentEmail: widget.currentEmail,
                      jwtToken: widget.jwtToken,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
