import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/recent_tracks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about_me.dart';
import '../top_data/top_scrobbles.dart';
import 'package:http/http.dart' as http;


class UserProfilePage extends StatefulWidget {
  final AboutData userData;

  UserProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isFollowing = false;
  String topSong = '';
  String imgSong = '';
  String topArtist = '';
  String imgArtist = '';
  String topAlbum = '';
  String imgAlbum = '';
  int totalScrobbles = 0;


  @override
  void initState() {
    super.initState();
    _fetchData();
    _checkIfFollowing();
    fetchTopSongData();
    fetchArtistSongData();
    fetchTopAlbumData();

  }

  void _fetchData() async {
    int scrobbles = await fetchTotalScrobbles(widget.userData.lastFMUsername);
    setState(() {
      totalScrobbles = scrobbles;
    });
  }

  void fetchTopSongData() async {
    final topData = await fetchTopSong(widget.userData.lastFMUsername);
    setState(() {
      print(topData['URL']);
      topSong = (topData['topSong'] ?? '') + " - " + (topData['topArtist'] ?? '');
      imgSong = topData['URL'] ?? '';
    });
  }

  void fetchArtistSongData() async {
    final topData = await fetchTopArtist(widget.userData.lastFMUsername);
    setState(() {
      topArtist = topData['topArtist'] ?? '';
      imgArtist = topData['URL'] ?? '';
    });
  }

  void fetchTopAlbumData() async {
    final topData = await fetchTopAlbum(widget.userData.lastFMUsername);
    setState(() {
      print(topData['URL']);
      topAlbum = (topData['topAlbum'] ?? '') + " - " + (topData['topArtist'] ?? '');
      imgAlbum = topData['URL'] ?? '';
    });
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
            //String topArtist = fetchTopArtist(widget.userData.lastFMUsername);
            //String topSong = fetchTopSong(widget.userData.lastFMUsername);

            Padding(
              padding: const EdgeInsets.all(0.0),
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
                    "Favourite Genre: " + widget.userData.favoriteGenre,
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
                      _buildFollowButton(Icons.person_add_alt_1, context),
                      const SizedBox(width: 16),
                      _buildStatButton(Icons.music_note, context),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _buildInfoCard('Scrobbles: $totalScrobbles'),
                  if (topSong.isNotEmpty) _buildDetailTile('Top Song', topSong, imgSong),
                  if (topArtist.isNotEmpty) _buildDetailTile('Top Artist', topArtist, imgArtist),
                  if (topArtist.isNotEmpty) _buildDetailTile('Top Album', topAlbum, imgAlbum),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDetailTile(String title, String detail, String imageUrl) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          imageUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),
          )
              : Icon(Icons.person, color: Colors.deepPurple, size: 30),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildStatButton(IconData icon, BuildContext context, {Color backgroundColor = Colors.red}) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecentTracksPage(lastFmUsername: widget.userData.lastFMUsername)),
        );
      },
      elevation: 0,
      backgroundColor: backgroundColor,
      icon: Icon(Icons.music_note),
      label: Text('Recent Tracks'),
    );
  }

  Widget _buildFollowButton (IconData icon, BuildContext context, {Color backgroundColor = Colors.deepPurple}) {
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
      child: Padding(
        padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
        child: CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(userData.profilePicUrl),
        ),
      ),
    );
  }

}

Future<int> fetchTotalScrobbles(String lastFMUsername) async {
  final _apiKey = dotenv.env['API_KEY'];
  final url = Uri.parse('http://ws.audioscrobbler.com/2.0/?method=user.getInfo&user=$lastFMUsername&api_key=$_apiKey&format=json');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final scrobbles = int.parse(data['user']['playcount']);
      return scrobbles;
    }
  } catch (e) {
    print('Error occurred: $e');
  }
  return 0; // Return 0 in case of an error
}


