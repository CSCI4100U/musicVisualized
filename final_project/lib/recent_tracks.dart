import 'package:final_project/about_me/about_page.dart';
import 'package:final_project/about_me/feed_page.dart';
import 'package:final_project/account/user.dart';
import 'package:final_project/top_data/geo_top_tracks.dart';
import 'package:final_project/top_data/top_scrobbles.dart';
import 'package:final_project/top_data/top_visulized_data.dart';
import 'package:final_project/utils/app_drawer.dart';
import 'package:final_project/utils/fetch_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'track_tile.dart';
import '../utils/db_utils.dart';

class RecentTracksPage extends StatefulWidget {
  final String? lastFmUsername;

  RecentTracksPage({Key? key, this.lastFmUsername}) : super(key: key);

  @override
  _RecentTracksPageState createState() => _RecentTracksPageState();
}

class _RecentTracksPageState extends State<RecentTracksPage> {
  List<dynamic> _tracks = [];
  bool _isLoading = true;
  String? _error;
  bool _isDialogShown = false;

  @override
  void initState() {
    super.initState();
    _fetchRecentTracks(lastFmUsername: widget.lastFmUsername);
  }

  void _showRecentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Welcome"),
          content: Text("This is the Recent Track Page."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                _showRecent2Dialog();
              },
            ),
          ],
        );
      },
    );
  }
  void _showRecent2Dialog() {
    if (!_isDialogShown) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Recent Tracks"),
            content: Text(
                "Explore your Recent Tracks page to see your latest music listens and stay updated with your current musical journey!"),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      _isDialogShown = true;
    }
  }

  void _fetchRecentTracks({String? lastFmUsername}) async {
    print('1');
    try {
      if (lastFmUsername == null) {
        final prefs = await SharedPreferences.getInstance();
        final String? currentUser = prefs.getString('username');

        if (currentUser == null) {
          throw Exception('No current user found');
        }

        final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
        lastFmUsername = await _databaseHelper.getLastFmUsername(currentUser);

        if (lastFmUsername == null) {
          throw Exception('Last.fm username not found for current user');
        }
      }

      print("Last Fm user is: $lastFmUsername");
      print("Getting link");
      //Get api key
      await dotenv.load(fileName: ".env");
      String _apiKey = dotenv.get('API_KEY');
      final response = await http.get(
        Uri.parse('https://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=$lastFmUsername&api_key=$_apiKey&format=json&limit=100'),
      );
      print(response.body);

      print("kekw");
      if (response.statusCode == 200) {
        print('did i make it?');
        final data = json.decode(response.body);
        setState(() {
          _tracks = data['recenttracks']['track'];
          _isLoading = false;
          _showRecentDialog();
        });
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('username');

  }




  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
          backgroundColor: Colors.black87,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
          backgroundColor: Colors.black87,
        ),
        body: Center(
          child: Text(_error!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Recent Tracks'),

        // automaticallyImplyLeading: false,
        backgroundColor: Colors.black87,
      ),
      body: ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          return TrackListTile(track: _tracks[index]);
        },
      ),
      drawer: AppDrawer(
        getCurrentUser: () async {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getString('username');
          },
      ),
    );

  }
}
