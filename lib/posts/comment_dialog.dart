import 'package:flutter/material.dart';
import 'comments/comments.dart';
import 'api_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CommentDialog extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final String currentEmail;

  CommentDialog({
    required this.postId,
    required this.currentUserId,
    required this.currentEmail,
  });

  @override
  _CommentDialogState createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  late Future<List<Comment>> comments;
  final TextEditingController _controller = TextEditingController();
  bool isSubmitting = false; // To track submission state

  @override
  void initState() {
    super.initState();
    comments = ApiService().fetchComments(widget.postId);
  }

  void _submitComment() async {
    if (_controller.text.isNotEmpty && !isSubmitting) {
      setState(() {
        isSubmitting = true; // Disable the button while submitting
      });

      await ApiService().createComment(
        widget.postId,
        _controller.text,
        widget.currentUserId,
      );

      // Reload the comments after posting
      setState(() {
        comments = ApiService().fetchComments(widget.postId);
        isSubmitting = false; // Enable the button again
      });

      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the height of the screen
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: EdgeInsets.zero,  // Remove margins
      child: Container(
        height: screenHeight * 0.6,  // Set height to 60% of the screen height
        child: Column(
          children: [
            // Comments section
            Expanded(
              child: FutureBuilder<List<Comment>>(
                future: comments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: SpinKitFadingCircle(color: Colors.grey, size: 50.0));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Failed to load comments'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No comments yet.'));
                  } else {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final comment = snapshot.data![index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(comment.profilePicture),
                          ),
                          title: Text(comment.username),
                          subtitle: Text(comment.comment),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            // Input field with send icon
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.comment, color: Colors.deepOrange),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: isSubmitting
                      ? SpinKitFadingCircle(color: Colors.deepOrange, size: 20) // Show spinner while submitting
                      : Icon(Icons.send, color: Colors.deepOrange),
                  onPressed: isSubmitting ? null : _submitComment, // Disable if submitting
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
