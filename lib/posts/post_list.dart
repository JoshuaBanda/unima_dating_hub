import 'package:flutter/material.dart';
import 'post/post.dart';
import 'comments/comments.dart';
import 'api_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';  // Import Google Fonts
import 'post_item.dart';

class PostListPage extends StatefulWidget {
  final int currentUserId;
  final String currentEmail;

  PostListPage({required this.currentUserId, required this.currentEmail});

  @override
  _PostListPageState createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  late Future<List<Post>> posts;

  final List<String> _carouselImages = [
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
    'assets/image4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    posts = ApiService().fetchPosts(); // Fetch posts on initial load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Text "Get your match" above the carousel
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'Get your match',
                style: GoogleFonts.dancingScript(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 77, 74, 73),
                ),
              ),
            ),

            // Carousel Slider Section
            CarouselSlider(
              items: _carouselImages.map((imagePath) {
                return Builder(
                  builder: (BuildContext context) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.4,
                      ),
                    );
                  },
                );
              }).toList(),
              options: CarouselOptions(
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 5),
                enlargeCenterPage: true,
                viewportFraction: 0.3,  // Display 3 images at once
                aspectRatio: 16 / 9,
              ),
            ),

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
