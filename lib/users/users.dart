class User {
  final String userid; // User ID
  final String firstName;
  final String lastName;
  final String profile;
  final String? profileImageUrl; // Optional field

  User({
    required this.userid,
    required this.firstName,
    required this.lastName,
    required this.profile,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userid: json['userid']?.toString() ?? '', // Ensure this is a string
      firstName: json['firstname'] ?? '', // Adjust key if necessary
      lastName: json['lastname'] ?? '', // Adjust key if necessary
      profile: json['profile'] ?? '',
      profileImageUrl: json['profileImageUrl'], // Include this if it exists in the JSON
    );
  }
}
