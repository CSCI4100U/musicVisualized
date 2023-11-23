import 'package:flutter/material.dart';
import 'about_me.dart';  // Make sure this import points to your AboutData class

class UserProfilePage extends StatelessWidget {
  final AboutData userData;

  UserProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _TopGradientSection(userData: userData),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    userData.name,
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userData.favoriteGenre,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(userData.bio),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoCard('Followers: ${userData.followers.length}'),
                      _buildInfoCard('Following: ${userData.following.length}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(Icons.person_add_alt_1, "Follow"),
                      const SizedBox(width: 16),
                      _buildActionButton(Icons.message_rounded, "Message", backgroundColor: Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {Color backgroundColor = Colors.deepPurple}) {
    return FloatingActionButton.extended(
      onPressed: () {},
      elevation: 0,
      backgroundColor: backgroundColor,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

class _TopGradientSection extends StatelessWidget {
  final AboutData userData;

  _TopGradientSection({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(userData.profilePicUrl),
      ),
    );
  }
}


