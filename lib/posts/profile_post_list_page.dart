import 'package:flutter/material.dart';
import 'post/post.dart';
import 'comments/comments.dart';
import 'api_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'post_item.dart';

class ProfilePostListPage extends StatefulWidget {
  final int currentUserId;  // The ID of the current user
  final String currentEmail; // The email of the current user
  final int secondUserId;   // The ID of the second user
  final String jwtToken;    // JWT token to authorize API requests

  // Constructor now accepts jwtToken as well
  ProfilePostListPage({
    required this.currentUserId,
    required this.currentEmail,
    required this.secondUserId, // Adding secondUserId to the constructor
    required this.jwtToken,     // Adding jwtToken to the constructor
  });

  @override
  _ProfilePostListPageState createState() => _ProfilePostListPageState();
}

class _ProfilePostListPageState extends State<ProfilePostListPage> {
  late Future<List<Post>> posts;

  @override
  void initState() {
    super.initState();
    // Now pass both jwtToken and secondUserId when calling fetchPostsByUserId
    posts = ApiService().fetchPostsByUserId(
      jwtToken: widget.jwtToken, // Pass jwtToken
      userId: widget.secondUserId, // Pass secondUserId as the userId
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // FutureBuilder to load the posts
            FutureBuilder<List<Post>>(
              future: posts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: SpinKitFadingCircle(color: Colors.grey, size: 50.0));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Failed to load posts'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No posts available'));
                } else {
                  List<Post> postsList = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: postsList.length,
                    itemBuilder: (context, index) {
                      final post = postsList[index];
                      return PostItem(
                        post: post,
                        currentUserId: widget.currentUserId,
                        currentEmail: widget.currentEmail,
                        jwtToken: widget.jwtToken,  // Pass the jwtToken here
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
