class Post {
  final int postId;
  final String description;
  final String photoUrl;
  final int userId;
  final String username;
  final String lastname;
  final String profilePicture;

  Post({
    required this.postId,
    required this.description,
    required this.photoUrl,
    required this.userId,
    required this.username,
    required this.lastname,
    required this.profilePicture,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['post_id'],
      description: json['description'],
      photoUrl: json['photo_url'],
      userId: json['user_id'],
      username: json['username'] ?? 'anonymous',
      lastname: json['lastname'] ?? '',
      profilePicture: json['profilepicture'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'description': description,
      'photo_url': photoUrl,
      'user_id': userId,
      'username': username,
      'lastname': lastname,
      'profilepicture': profilePicture,
    };
  }
}
