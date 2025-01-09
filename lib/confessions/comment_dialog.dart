import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'comments/comments.dart'; // Your comments model
import 'api_service.dart'; // Your API service

class CommentDialog extends StatefulWidget {
  final int confessionId;
  final int currentUserId;
  final String currentEmail;
  final String jwtToken;

  CommentDialog({
    required this.confessionId,
    required this.currentUserId,
    required this.currentEmail,
    required this.jwtToken,
  });

  @override
  _CommentDialogState createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  late Future<List<Comment>> comments;
  final TextEditingController _controller = TextEditingController();
  bool isSubmitting = false;
  bool isDeleting = false; // Track if deletion is in progress
  bool isEditing = false; // Track if editing is in progress
  Comment? selectedComment;

  @override
  void initState() {
    super.initState();
    comments = ApiService().fetchComments(
      jwtToken: widget.jwtToken,
      confessionId: widget.confessionId,
    );
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp).add(Duration(hours: 2));
    return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
  }

  void _submitComment() async {
    if (_controller.text.isNotEmpty && !isSubmitting) {
      setState(() {
        isSubmitting = true;
      });

      // If we are editing, update the existing comment
      if (isEditing && selectedComment != null) {
        await ApiService().updateComment(
          jwtToken: widget.jwtToken,
          confessionId: widget.confessionId,
          commentId: selectedComment!.commentId,
          newCommentText: _controller.text,
        );
      } else {
        // Otherwise, create a new comment
        await ApiService().createComment(
          jwtToken: widget.jwtToken,
          confessionId: widget.confessionId,
          commentText: _controller.text,
          userId: widget.currentUserId,
        );
      }

      setState(() {
        comments = ApiService().fetchComments(
          jwtToken: widget.jwtToken,
          confessionId: widget.confessionId,
        );
        isSubmitting = false;
        isEditing = false;
      });

      _controller.clear();
    }
  }

  void _deleteComment(int commentId) async {
    setState(() {
      isDeleting = true; // Start the deletion process
    });

    try {
      // Call your API to delete the comment by ID
      await ApiService().deleteComment(
        jwtToken: widget.jwtToken,
        confessionId: widget.confessionId,
        commentId: commentId,
      );

      setState(() {
        comments = ApiService().fetchComments(
          jwtToken: widget.jwtToken,
          confessionId: widget.confessionId,
        );
        isDeleting = false; // End the deletion process
      });

      // Show success feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isDeleting = false; // End the deletion process if error occurs
      });

      // Show error feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete comment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editComment(Comment comment) {
    setState(() {
      isEditing = true; // Enable editing
      selectedComment = comment;
      _controller.text = comment.comment; // Populate the controller with the comment text
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.only(top: 200, left: 0, right: 0, bottom: 0),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Comments section
            Expanded(
              child: FutureBuilder<List<Comment>>(
                future: comments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: SpinKitFadingCircle(
                        color: Colors.grey,
                        size: 50.0,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Failed to load comments'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No comments yet.'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final comment = snapshot.data![index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedComment = selectedComment == comment
                                  ? null // Deselect if the same comment is tapped again
                                  : comment; // Select the comment
                            });
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(comment.profilePicture),
                            ),
                            title: Text(comment.username),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment.comment),
                                SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(comment.createdAt),
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                if (selectedComment == comment && comment.userId == widget.currentUserId) ...[
                                  SizedBox(height: 8), // Add some space before the action buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.edit, color: Colors.orange),
                                          onPressed: () {
                                            _editComment(comment);
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 8), // Space between buttons
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            _deleteComment(comment.commentId);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            // Input field and button at the bottom
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: isEditing ? 'Edit your comment...' : 'Write a comment...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.comment, color: Colors.deepOrange),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: isSubmitting
                        ? SpinKitFadingCircle(color: Colors.red, size: 20)
                        : Icon(Icons.send, color: Colors.red),
                    onPressed: isSubmitting ? null : _submitComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
