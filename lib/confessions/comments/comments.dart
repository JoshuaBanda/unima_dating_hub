class Comment {
  final int commentId;
  final int userId; // Add this field for the user's ID
  final String username;
  final String profilePicture;
  final String comment;
  final String createdAt; // New field for the creation date

  Comment({
    required this.commentId,
    required this.userId, // Include userId in the constructor
    required this.username,
    required this.profilePicture,
    required this.comment,
    required this.createdAt, // Initialize createdAt
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['confession_comment_id'],
      userId: json['user_id'] ?? 0, // Ensure to parse the user_id from the response
      username: json['username'] ?? 'anonymous',
      profilePicture: json['profilepicture'] ?? '',
      comment: json['confession_comment'] ?? '',
      createdAt: json['created_at'] ?? '', // Parse created_at or default to empty string
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'user_id': userId, // Include userId in the toJson method
      'username': username,
      'profile_picture': profilePicture,
      'comment': comment,
      'created_at': createdAt, // Include createdAt in the toJson method
    };
  }
}
