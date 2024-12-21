class Post {
  final int postId;
  final String description;
  final String photoUrl;
  final int userId;
  final String username;
  final String lastname;
  final String profilePicture;
  final DateTime createdAt; // Field to store the creation date of the post

  Post({
    required this.postId,
    required this.description,
    required this.photoUrl,
    required this.userId,
    required this.username,
    required this.lastname,
    required this.profilePicture,
    required this.createdAt, // Initialize createdAt
  });

  // Factory method to create a Post object from JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['post_id'],
      description: json['description'],
      photoUrl: json['photo_url'],
      userId: json['user_id'],
      username: json['username'] ?? 'anonymous',
      lastname: json['lastname'] ?? '',
      profilePicture: json['profilepicture'] ?? '',
      createdAt: DateTime.parse(json['created_at']), // Parse the date string into DateTime
    );
  }

  // Method to convert a Post object into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'description': description,
      'photo_url': photoUrl,
      'user_id': userId,
      'username': username,
      'lastname': lastname,
      'profilepicture': profilePicture,
      'created_at': createdAt.toIso8601String(), // Convert DateTime to ISO 8601 string
    };
  }
}
