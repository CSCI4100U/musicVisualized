import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

  void fetchFollowedUsers() async {
    List<dynamic> users = await getFollowedUsers();

    setState(() {
      followedUsers = users;
    });

    for (var user in users) {
      var tracks = await getRecentTracksForUser(user);
      setState(() {
        recentTracks[user] = tracks;
      });
    }
  }

  Future<List<String>> getFollowedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUsername = prefs.getString('username');

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('aboutme')
          .where('username', isEqualTo: currentUsername)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var following = querySnapshot.docs.first.get('following');
        if (following is List) {
          return following.map((item) => item.toString()).toList();
        }
      }
    } catch (e) {
      print("Error fetching document: $e");
    }
    return [];
  }


  Future<List<dynamic>> getRecentTracksForUser(String username) async {
    await dotenv.load(fileName: ".env");
    String _apiKey = dotenv.get('API_KEY');
    final String url = 'https://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=$username&api_key=$_apiKey&format=json&limit=1';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> tracks = data['recenttracks']['track'];
        return tracks;
      } else {
        print('Failed to fetch data: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error occurred: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed'),
        backgroundColor: Colors.black87,
      ),
      body: ListView.builder(
        itemCount: followedUsers.length,
        itemBuilder: (context, index) {
          var user = followedUsers[index];
          var tracks = recentTracks[user] ?? [];

          return ListTile(
            title: Text(user),
            subtitle: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tracks.length,
              itemBuilder: (context, trackIndex) {
                var track = tracks[trackIndex];
                return ListTile(
                  title: Text(track['name'] ?? 'Unknown Track'),
                  subtitle: Text(track['artist']['#text'] ?? 'Unknown Artist'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
