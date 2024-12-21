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

      await ApiService().createComment(
        jwtToken: widget.jwtToken,
        postId: widget.postId,
        commentText: _controller.text,
        userId: widget.currentUserId,
      );

      setState(() {
        comments = ApiService().fetchComments(
          jwtToken: widget.jwtToken,
          postId: widget.postId,
        );
        isSubmitting = false;
      });

      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6, // Dynamic height
        child: Column(
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
                        return ListTile(
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
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            // Input field and button
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
                IconButton(
                  icon: isSubmitting
                      ? SpinKitFadingCircle(color: Colors.deepOrange, size: 20)
                      : Icon(Icons.send, color: Colors.deepOrange),
                  onPressed: isSubmitting ? null : _submitComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
