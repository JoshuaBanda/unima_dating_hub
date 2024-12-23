class Confession {
  final int confessionId;
  final String description;
  final String photoUrl;
  final int userId;
  final String username;
  final String lastname;
  final String profilePicture;
  final DateTime createdAt; // Field to store the creation date of the post

  Confession({
    required this.confessionId,
    required this.description,
    required this.photoUrl,
    required this.userId,
    required this.username,
    required this.lastname,
    required this.profilePicture,
    required this.createdAt, // Initialize createdAt
  });

  // Factory method to create a Confession object from JSON
  factory Confession.fromJson(Map<String, dynamic> json) {
    return Confession(
      confessionId: json['confession_id'] ?? 0, // Handle null or missing values
      description: json['description'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? 'anonymous',
      lastname: json['lastname'] ?? '',
      profilePicture: json['profilepicture'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(), // Default to current date if null
    );
  }

  // Method to convert a Confession object into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'confession_id': confessionId, // Corrected key
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
