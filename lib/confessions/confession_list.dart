import 'package:flutter/material.dart';
import 'connfession/confession.dart';
import 'api_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'confession_item.dart';

class ConfessionListPage extends StatefulWidget {
  final int currentUserId;
  final String currentEmail;
  final String jwtToken;

  ConfessionListPage({
    required this.currentUserId,
    required this.currentEmail,
    required this.jwtToken,
  });

  @override
  _ConfessionListPageState createState() => _ConfessionListPageState();
}

class _ConfessionListPageState extends State<ConfessionListPage> {
  late Future<List<Confession>> confessions;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int currentPage = 1;
  int limit = 10;
  List<Confession> allConfessions = [];

  @override
  void initState() {
    super.initState();
    _loadConfessions();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
          !_isLoading) {
        _loadMoreConfessions();
      }
    });
  }

  _loadConfessions() {
    setState(() {
      confessions = ApiService().fetchConfessions(
        jwtToken: widget.jwtToken,
        page: currentPage,
        limit: limit,
      );
    });
  }

  _loadMoreConfessions() async {
    setState(() {
      _isLoading = true;
    });

    List<Confession> newConfessions = await ApiService().fetchConfessions(
      jwtToken: widget.jwtToken,
      page: currentPage + 1,
      limit: limit,
    );

    setState(() {
      currentPage++;
      allConfessions.addAll(newConfessions);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200, // Set background color here
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                color: Colors.pink.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'We Don’t Judge',
                    style: GoogleFonts.dancingScript(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            FutureBuilder<List<Confession>>(
              future: confessions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SpinKitFadingCircle(
                      color: Colors.pink.shade300,
                      size: 50.0,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load confessions',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 16,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No confessions available',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 16,
                      ),
                    ),
                  );
                } else {
                  List<Confession> confessionsList = snapshot.data!;

                  if (allConfessions.isEmpty) {
                    allConfessions.addAll(confessionsList);
                  }

                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: allConfessions.length,
                        itemBuilder: (context, index) {
                          final confession = allConfessions[index];
                          return ConfessionItem(
                            confession: confession,
                            currentUserId: widget.currentUserId,
                            currentEmail: widget.currentEmail,
                            jwtToken: widget.jwtToken,
                          );
                        },
                      ),
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: SpinKitFadingCircle(
                            color: Colors.pink.shade300,
                            size: 40.0,
                          ),
                        ),
                      if (!_isLoading && allConfessions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'Scroll down for more confessions',
                            style: GoogleFonts.dancingScript(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.pink.shade500,
                            ),
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
    _scrollController.dispose();
  }
}
