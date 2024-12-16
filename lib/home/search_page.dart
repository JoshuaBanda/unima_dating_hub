import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users or posts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            // Implement your search results UI here
            Expanded(
              child: ListView(
                children: [
                  // Example search result (replace with actual data)
                  ListTile(
                    title: Text('Search Result 1'),
                  ),
                  ListTile(
                    title: Text('Search Result 2'),
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
