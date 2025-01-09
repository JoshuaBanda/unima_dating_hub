import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'comments/comments.dart'; // Your comments model
import 'api_service.dart'; // Your API service

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Comments Example')),
        body: Center(
          child: ElevatedButton(
            child: Text('Open Comments'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CommentDialog(
                  postId: 1,
                  currentUserId: 1,
                  currentEmail: 'user@example.com',
                  jwtToken: 'your_jwt_token',
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CommentDialog extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final String currentEmail;
  final String jwtToken;

  CommentDialog({
    required this.postId,
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
  bool isEditing = false;
  Comment? selectedComment;

  @override
  void initState() {
    super.initState();
    comments = ApiService().fetchComments(
      jwtToken: widget.jwtToken,
      postId: widget.postId,
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
          postId: widget.postId,
          commentId: selectedComment!.commentId,
          newCommentText: _controller.text,
        );
      } else {
        // Otherwise, create a new comment
        await ApiService().createComment(
          jwtToken: widget.jwtToken,
          postId: widget.postId,
          commentText: _controller.text,
          userId: widget.currentUserId,
        );
      }

      setState(() {
        comments = ApiService().fetchComments(
          jwtToken: widget.jwtToken,
          postId: widget.postId,
        );
        isSubmitting = false;
        isEditing = false;
        selectedComment = null; // Reset the selected comment
      });

      _controller.clear();
    }
  }

  void _deleteComment(int commentId) async {
    try {
      await ApiService().deleteComment(
        jwtToken: widget.jwtToken,
        postId: widget.postId,
        commentId: commentId,
      );
      setState(() {
        comments = ApiService().fetchComments(
          jwtToken: widget.jwtToken,
          postId: widget.postId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete comment. Please try again.')),
      );
    }
  }

  void _editComment(Comment comment) {
    setState(() {
      isEditing = true;
      selectedComment = comment;
      _controller.text = comment.comment;
    });
  }

  void _selectComment(Comment comment) {
    setState(() {
      if (selectedComment == comment) {
        // Deselect the comment if it's already selected
        selectedComment = null;
      } else {
        // Select the comment
        selectedComment = comment;
      }
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
                        bool isSelected = selectedComment == comment;
                        return GestureDetector(
                          onTap: () => _selectComment(comment),
                          child: ListTile(
                            tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
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
                                // Show edit and delete buttons only for the current user's comments
                                if (isSelected && comment.userId == widget.currentUserId) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          _editComment(comment); // Edit the comment when tapped
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.edit, color: Colors.orange),
                                            onPressed: () {
                                              _editComment(comment); // Edit the comment when clicked
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          _deleteComment(comment.commentId); // Delete the comment when tapped
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              _deleteComment(comment.commentId); // Delete the comment when clicked
                                            },
                                          ),
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
                        ? SpinKitFadingCircle(color: Colors.deepOrange, size: 20)
                        : Icon(Icons.send, color: Colors.deepOrange),
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
