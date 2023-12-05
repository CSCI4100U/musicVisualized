class AboutData {
  String username;
  String name;
  String favoriteGenre;
  String bio;
  String profilePicUrl;
  String lastFMUsername;
  List<String> following;
  List<String> followers;


  AboutData({
    required this.username,
    required this.name,
    required this.favoriteGenre,
    required this.bio,
    required this.profilePicUrl,
    required this.lastFMUsername,
    required this.following,
    required this.followers,
  });

  factory AboutData.fromMap(Map<String, dynamic> data) {
    return AboutData(
      username: data['username'],
      name: data['name'],
      favoriteGenre: data['favoriteGenre'],
      bio: data['bio'],
      profilePicUrl: data['profilePicUrl'],
      lastFMUsername: data['lastFMUsername'],
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
    );
  }

  void addFollower(String followerName) {
    followers.add(followerName);
  }

  void removeFollower(String followerName) {
    followers.remove(followerName);
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'name': name,
      'lastFMUsername': lastFMUsername,
      'favoriteGenre': favoriteGenre,
      'bio': bio,
      'profilePicUrl': profilePicUrl,
      'following': following,
      'followers': followers,
    };
  }
}
