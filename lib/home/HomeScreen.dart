import 'package:flutter/material.dart';
import 'package:unima_dating_hub/posts/post_list.dart'; // Ensure this import is correct

class HomeScreen extends StatefulWidget {
  final int currentUserId;
  final String currentEmail;

  const HomeScreen({
    Key? key,
    required this.currentUserId,
    required this.currentEmail,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 16), // For some spacing before the PostList
                // Instead of wrapping with SizedBox, ensure PostListPage is flexible
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height), // Limit height
                  child: PostListPage(
                    currentUserId: widget.currentUserId, // Pass currentUserId to PostList
                    currentEmail: widget.currentEmail,   // Pass currentEmail to PostList
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
