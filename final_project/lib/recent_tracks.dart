import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'track_tile.dart';

class RecentTracksPage extends StatefulWidget {
  @override
  _RecentTracksPageState createState() => _RecentTracksPageState();
}

class _RecentTracksPageState extends State<RecentTracksPage> {
  final String _apiKey = dotenv.get('API_KEY');
  final String _user = 'TejS40';
  List<dynamic> _tracks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRecentTracks();
  }

  Future<void> _fetchRecentTracks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=$_user&api_key=$_apiKey&format=json&limit=10'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          setState(() {
            _error = data['message'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _tracks = data['recenttracks']['track'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load tracks. Status Code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text(_error!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Recent Tracks'),
      ),
      body: ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          return TrackListTile(track: _tracks[index]);
        },
      ),
    );
  }
}
