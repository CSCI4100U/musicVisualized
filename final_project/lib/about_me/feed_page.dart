import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/app_drawer.dart';
import 'feed_tiles.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<dynamic> followedUsers = [];
  Map<String, dynamic> recentTracks = {};

  @override
  void initState() {
    super.initState();
    fetchFollowedUsers();
  }

  //Fetches the tracks for the users that the current user is following
  void fetchFollowedUsers() async {
    List<dynamic> users = await getFollowedUsers();
    setState(() {
      followedUsers = users;
    });

    for (var user in users) {
      print(user);
      var tracks = await getRecentTracksForUser(user);
      print(tracks);
      setState(() {
        recentTracks[user] = tracks;
      });
    }
  }

  //Fetches the users that the current user is following
  Future<List<String>> getFollowedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUsername = prefs.getString('username');

    List<String> followedUsersLastFMUsernames = [];

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('aboutme')
          .where('username', isEqualTo: currentUsername)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var followingList = querySnapshot.docs.first.data()['following'] as List<dynamic>;

        for (var followedUsername in followingList) {
          var userDoc = await FirebaseFirestore.instance
              .collection('aboutme')
              .where('username', isEqualTo: followedUsername)
              .limit(1)
              .get();

          if (userDoc.docs.isNotEmpty) {
            var lastFMUsername = userDoc.docs.first.data()['lastFMUsername'] as String;
            followedUsersLastFMUsernames.add(lastFMUsername);
          }
        }
      }
    } catch (e) {
      print("Error fetching document: $e");
    }

    return followedUsersLastFMUsernames;
  }


  //Fetches the most recent track for a given user
  Future<List<dynamic>> getRecentTracksForUser(String username) async {
    await dotenv.load(fileName: ".env");
    String _apiKey = dotenv.get('API_KEY');
    final String url = 'https://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=$username&api_key=$_apiKey&format=json&limit=1';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        List<dynamic> tracks = data['recenttracks']['track'];
        return tracks.isNotEmpty ? [tracks.first] : [];
      } else {
        print('Failed to fetch data: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error occurred: $e');
      return [];
    }
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed'),
        backgroundColor: Colors.black87,
      ),
      drawer: AppDrawer(
        getCurrentUser: () async {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getString('username');
        },
      ),
      body: ListView.builder(
        itemCount: followedUsers.length,
        itemBuilder: (context, index) {
          var user = followedUsers[index];
          var tracks = recentTracks[user] ?? [];

          return Card(
            margin: EdgeInsets.all(8),
            elevation: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    user,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: tracks.length,
                  itemBuilder: (context, trackIndex) {
                    var track = tracks[trackIndex];
                    return TrackTile(
                      trackName: track['name'] ?? 'Unknown Track',
                      artistName: track['artist']['#text'] ?? 'Unknown Artist',
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}