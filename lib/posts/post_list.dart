import 'package:flutter/material.dart';
import 'post/post.dart';
import 'api_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'post_item.dart';

class PostListPage extends StatefulWidget {
  final int currentUserId;
  final String currentEmail;
  final String jwtToken; // Add jwtToken parameter

  PostListPage({
    required this.currentUserId,
    required this.currentEmail,
    required this.jwtToken, // Initialize jwtToken
  });

  @override
  _PostListPageState createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  late Future<List<Post>> posts;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false; // To track if more posts are being loaded
  int currentPage = 1; // Track the current page for pagination
  int limit = 10; // Limit number of posts per page
  List<Post> allPosts = []; // List to hold all posts

  final List<String> _carouselImages = [
    'assets/image1.jpg',
    'assets/image7.jpg',
    'assets/image3.jpg',
    'assets/image4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts(); // Load initial posts

    // Listen to the scroll controller to detect when the user reaches the bottom
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
        _loadMorePosts(); // Load more posts when reaching the bottom
      }
    });
  }

  // Function to load initial posts
  _loadPosts() {
    setState(() {
      posts = ApiService().fetchPosts(
        jwtToken: widget.jwtToken, 
        page: currentPage,
        limit: limit,
      );
    });
  }

  // Function to load more posts when the user reaches the end
  _loadMorePosts() async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });

    // Fetch more posts from the API
    List<Post> newPosts = await ApiService().fetchPosts(
      jwtToken: widget.jwtToken, // Pass jwtToken to fetchPosts
      page: currentPage + 1,
      limit: limit,
    );

    setState(() {
      currentPage++; // Increment page number after fetching more posts
      allPosts.addAll(newPosts); // Add the new posts to the list
      _isLoading = false; // Set loading state to false
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController, // Attach the controller to the scroll view
        child: Column(
          children: [
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
                viewportFraction: 0.3,
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
                  List<Post> postsList = snapshot.data!; // Posts fetched from API

                  // Update the allPosts list only if it is the first time fetching posts
                  if (allPosts.isEmpty) {
                    allPosts.addAll(postsList); // Only add the posts if it's the first time
                  }

                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: allPosts.length,
                        itemBuilder: (context, index) {
                          final post = allPosts[index];
                          return PostItem(
                            post: post,
                            currentUserId: widget.currentUserId,
                            currentEmail: widget.currentEmail,
                            jwtToken: widget.jwtToken, // Pass jwtToken to PostItem
                          );
                        },
                      ),
                      // Show "Get more posts" text and spinner if more posts are loading
                      if (!_isLoading && allPosts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 200.0, horizontal: 20.0), // Added padding
                          child: Column(
                            children: [
                              Text(
                                'Get more posts',
                                style: GoogleFonts.dancingScript(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 77, 74, 73),
                                ),
                              ),
                              SizedBox(height: 10), // Adding some space between text and spinner
                              SpinKitFadingCircle(color: Colors.grey, size: 50.0),
                            ],
                          ),
                        ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose(); // Clean up the controller when the widget is disposed
  }
}
