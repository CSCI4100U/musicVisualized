import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about_me.dart';

class UserProfilePage extends StatefulWidget {
  final AboutData userData;

  UserProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUsername = prefs.getString('username');
    if (currentUsername != null) {
      final currentUserDoc = await _getDocumentReferenceByUsername(currentUsername);
      if (currentUserDoc != null) {
        final DocumentSnapshot currentUserData = await currentUserDoc.get();
        if (currentUserData.exists && currentUserData.data() != null) {
          Map<String, dynamic> userDataMap = currentUserData.data() as Map<String, dynamic>;
          List followingList = userDataMap['following'] as List<dynamic>? ?? [];
          setState(() {
            isFollowing = followingList.contains(widget.userData.username);
          });
        }
      }
    }
  }


  Future<void> _handleFollow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUsername = prefs.getString('username');
    final String followedUsername = widget.userData.username;

    if (currentUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to follow')),
      );
      return;
    }

    final currentUserDoc = await _getDocumentReferenceByUsername(currentUsername);
    final followedUserDoc = await _getDocumentReferenceByUsername(followedUsername);

    if (currentUserDoc == null || followedUserDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to find user profiles')),
      );
      return;
    }

    currentUserDoc.update({
      'following': FieldValue.arrayUnion([followedUsername])
    });

    followedUserDoc.update({
      'followers': FieldValue.arrayUnion([currentUsername])
    }).then((_) {
      setState(() {
        isFollowing = true;
        widget.userData.addFollower(currentUsername);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are now following ${widget.userData.username}')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to follow: $error')),
      );
    });
  }

  Future<DocumentReference?> _getDocumentReferenceByUsername(String username) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('aboutme')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.reference;
      }
    } catch (e) {
      print("Error fetching document: $e");
    }
    return null;
  }

  Future<void> _handleUnfollow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUsername = prefs.getString('username');
    final String unfollowedUsername = widget.userData.username;

    if (currentUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to unfollow')),
      );
      return;
    }

    final currentUserDoc = await _getDocumentReferenceByUsername(currentUsername);
    final unfollowedUserDoc = await _getDocumentReferenceByUsername(unfollowedUsername);

    if (currentUserDoc == null || unfollowedUserDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to find user profiles')),
      );
      return;
    }

    currentUserDoc.update({
      'following': FieldValue.arrayRemove([unfollowedUsername])
    });

    unfollowedUserDoc.update({
      'followers': FieldValue.arrayRemove([currentUsername])
    }).then((_) {
      setState(() {
        isFollowing = false;
        widget.userData.removeFollower(currentUsername);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have unfollowed ${widget.userData.name}')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unfollow: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _TopGradientSection(userData: widget.userData),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    widget.userData.name,
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.userData.favoriteGenre,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(widget.userData.bio),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoCard('Followers: ${widget.userData.followers.length}'),
                      _buildInfoCard('Following: ${widget.userData.following.length}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(Icons.person_add_alt_1, context),
                      const SizedBox(width: 16),
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

  Widget _buildActionButton(IconData icon, BuildContext context, {Color backgroundColor = Colors.deepPurple}) {
    String label = isFollowing ? 'Unfollow' : 'Follow';
    return FloatingActionButton.extended(
      onPressed: () {
        if (isFollowing) {
          _handleUnfollow(context);
        } else {
          _handleFollow(context);
        }
      },
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
