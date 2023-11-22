class AboutData {
  String name;
  String favoriteGenre;
  String bio;
  String profilePicUrl;
  List<String> following;
  List<String> followers;

  AboutData({
    required this.name,
    required this.favoriteGenre,
    required this.bio,
    required this.profilePicUrl,
    required this.following,
    required this.followers,
  });

  factory AboutData.fromMap(Map<String, dynamic> data) {
    return AboutData(
      name: data['name'],
      favoriteGenre: data['favoriteGenre'],
      bio: data['bio'],
      profilePicUrl: data['profilePicUrl'],
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'favoriteGenre': favoriteGenre,
      'bio': bio,
      'profilePicUrl': profilePicUrl,
      'following': following,
      'followers': followers,
    };
  }
}
