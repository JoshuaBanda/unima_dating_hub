class Comment {
  final int commentId;
  final String username;
  final String profilePicture;
  final String comment;
  final String createdAt; // New field for the creation date
  final int userId; // Add the userId field

  Comment({
    required this.commentId,
    required this.username,
    required this.profilePicture,
    required this.comment,
    required this.createdAt, // Initialize createdAt
    required this.userId, // Initialize userId
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'],
      username: json['username'] ?? 'anonymous',
      profilePicture: json['profilepicture'] ?? '', // Corrected key name
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '', // Parse created_at or default to empty string
      userId: json['user_id'] ?? 0, // Assuming the user ID is in the response as 'user_id'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'username': username,
      'profile_picture': profilePicture,
      'comment': comment,
      'created_at': createdAt, // Include createdAt in the toJson method
      'user_id': userId, // Include userId in the toJson method
    };
  }
}
