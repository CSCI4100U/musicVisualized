import 'package:flutter/material.dart';
import 'about_me.dart';  // Make sure this import points to your AboutData class

class UserProfilePage extends StatelessWidget {
  final AboutData userData;

  UserProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userData.name),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              CircleAvatar(
                backgroundImage: NetworkImage(userData.profilePicUrl),
                radius: 60,
                backgroundColor: Colors.deepPurple.shade50,
              ),
              SizedBox(height: 20),
              Text(
                userData.name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 15),
              _buildInfoCard('Favorite Genre: ${userData.favoriteGenre}'),
              _buildInfoCard('Bio: ${userData.bio}'),
              _buildInfoCard('Followers: ${userData.followers.length}'),
              _buildInfoCard('Following: ${userData.following.length}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }
}
