class AboutData {
  String name;
  String favoriteGenre;
  String bio;
  String profilePicUrl;

  AboutData({required this.name, required this.favoriteGenre, required this.bio, required this.profilePicUrl});

  factory AboutData.fromMap(Map<String, dynamic> data) {
    return AboutData(
      name: data['name'],
      favoriteGenre: data['favoriteGenre'],
      bio: data['bio'],
      profilePicUrl: data['profilePicUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'favoriteGenre': favoriteGenre,
      'bio': bio,
      'profilePicUrl': profilePicUrl,
    };
  }
}
