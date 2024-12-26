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
    String profileImage = "https://res.cloudinary.com/dfahzd3ky/image/upload/v1734981920/farmsmart/theater-mask-red-curtain_23-2150062785.jpg.jpg";

    bool isValidUrl = profileImage.startsWith('http://') ||
        profileImage.startsWith('https://');
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
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: const [
                        Icon(Icons.report, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Report Confession'),
                      ],
                    ),
                  ),
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
              borderRadius: BorderRadius.circular(12.0), // Optional: Adjust the radius to match your design
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink, const Color.fromARGB(174, 244, 67, 54)], // Gradient from pink to red
                  begin: Alignment.topLeft, // Gradient starts from the top left
                  end: Alignment.bottomRight, // Gradient ends at the bottom right
                ),
                borderRadius: BorderRadius.circular(12.0), // Optional: Round the corners for the gradient
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  widget.confession.description,
                  style: const TextStyle(fontSize: 16, color: Colors.white), // Change text color to white for contrast
                ),
              ),
            ),
          ),


          // Actions Section (Like and Comment Buttons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.thumb_up,
                  color: isLiked ? Colors.redAccent : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    isLiked = !isLiked;
                  });
                },
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
