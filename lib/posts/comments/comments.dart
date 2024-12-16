class Comment {
  final int commentId;
  final String username;
  final String profilePicture;
  final String comment;

  Comment({
    required this.commentId,
    required this.username,
    required this.profilePicture,
    required this.comment,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'],
      username: json['username'] ?? 'anonymous',
      profilePicture: json['profile_picture'] ?? '',
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'username': username,
      'profile_picture': profilePicture,
      'comment': comment,
    };
  }
}
