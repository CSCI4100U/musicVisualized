import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> getSpotifyAccessToken() async {
  final clientId = dotenv.get('SPOTIFY_CLIENT_ID');
  final clientSecret = dotenv.get('SPOTIFY_CLIENT_SECRET');

  final clientCredentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

  final response = await http.post(
    Uri.parse('https://accounts.spotify.com/api/token'),
    headers: {
      'Authorization': 'Basic $clientCredentials',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {'grant_type': 'client_credentials'},
  );

  if (response.statusCode == 200) {
    final tokenData = json.decode(response.body);
    print("POG");
    return tokenData['access_token'];
  } else {
    throw Exception('Failed to get Spotify access token');
  }
}


Future<List<dynamic>> fetchMostStreamedTracks(String country) async {
  String token = await getSpotifyAccessToken();
  print("????");

  var playlistsResponse = await http.get(
    Uri.parse('https://api.spotify.com/v1/browse/categories/categories_id/playlists'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  var playlistsData = json.decode(playlistsResponse.body);
  print("2");
  var playlistId = playlistsData['playlists']['items'][0]['id'];
  print("3");
  var tracksResponse = await http.get(
    Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  var tracksData = json.decode(tracksResponse.body);
  print('1');
  print(tracksData['items']);
  return tracksData['items'];
}

void displayMostStreamedTracks() async {
  var tracks = await fetchMostStreamedTracks('CA');
}

class MostStreamedTracksPage extends StatefulWidget {
  @override
  _MostStreamedTracksPageState createState() => _MostStreamedTracksPageState();
}

class _MostStreamedTracksPageState extends State<MostStreamedTracksPage> {
  List<dynamic> _tracks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    displayMostStreamedTracks('CA');
  }

  void displayMostStreamedTracks(String countryId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var tracks = await fetchMostStreamedTracks(countryId);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Most Streamed Tracks'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          var track = _tracks[index]['track'];
          print(track);
          return ListTile(
            title: Text(track['name']),
            subtitle: Text(track['artists'][0]['name']),
            leading: Image.network(track['album']['images'][0]['url']),
          );
        },
      ),
    );
  }
}