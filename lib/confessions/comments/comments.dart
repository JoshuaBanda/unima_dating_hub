class Comment {
  final int commentId;
  final String username;
  final String profilePicture;
  final String comment;
  final String createdAt; // New field for the creation date

  Comment({
    required this.commentId,
    required this.username,
    required this.profilePicture,
    required this.comment,
    required this.createdAt, // Initialize createdAt
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'],
      username: json['username'] ?? 'anonymous',
      profilePicture: json['profile_picture'] ?? '',
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '', // Parse created_at or default to empty string
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'username': username,
      'profile_picture': profilePicture,
      'comment': comment,
      'created_at': createdAt, // Include createdAt in the toJson method
    };
  }
}
