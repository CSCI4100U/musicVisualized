import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String> fetchTrackImageUrl(String artist, String track) async {
  await dotenv.load();
  final accessToken = await getSpotifyAccessToken();

  final artistQueryParam = Uri.encodeQueryComponent(artist);
  final trackQueryParam = Uri.encodeQueryComponent(track);

  final searchUrl = Uri.parse(
      'https://api.spotify.com/v1/search?q=track:"$trackQueryParam" artist:"$artistQueryParam"&type=track&limit=1'
  );

  final response = await http.get(searchUrl, headers: {
    'Authorization': 'Bearer $accessToken',
  });

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['tracks']['items'].isNotEmpty) {
      final trackImageUrl = data['tracks']['items'][0]['album']['images'][0]['url'];
      return trackImageUrl;
    }
  }

  // Handle error or return a default image URL
  return 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
}

Future<String> fetchAlbumImageUrl(String artist, String album) async {
  await dotenv.load();
  final accessToken = await getSpotifyAccessToken();

  final artistQueryParam = Uri.encodeQueryComponent(artist);
  final albumQueryParam = Uri.encodeQueryComponent(album);

  final searchUrl = Uri.parse(
      'https://api.spotify.com/v1/search?q=album:"$albumQueryParam" artist:"$artistQueryParam"&type=album&limit=1'
  );

  final response = await http.get(searchUrl, headers: {
    'Authorization': 'Bearer $accessToken',
  });
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['albums']['items'].isNotEmpty) {
      final albumImageUrl = data['albums']['items'][0]['images'][0]['url'];

      return albumImageUrl;
    }
  }


  // Handle error or return a default image URL
  return 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
}

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
    return tokenData['access_token'];
  } else {
    throw Exception('Failed to get Spotify access token');
  }
}



Future<String> fetchArtistImageUrl(String artist) async {
  await dotenv.load();
  final accessToken = await getSpotifyAccessToken();

  final artistQueryParam = Uri.encodeQueryComponent(artist);

  final searchUrl = Uri.parse(
      'https://api.spotify.com/v1/search?q=artist:"$artistQueryParam"&type=artist&limit=1'
  );

  final response = await http.get(searchUrl, headers: {
    'Authorization': 'Bearer $accessToken',
  });

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['artists']['items'].isNotEmpty) {
      final artistId = data['artists']['items'][0]['id'];
      final artistDetailsUrl = Uri.parse('https://api.spotify.com/v1/artists/$artistId');
      final artistDetailsResponse = await http.get(artistDetailsUrl, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (artistDetailsResponse.statusCode == 200) {
        final artistDetails = json.decode(artistDetailsResponse.body);
        if (artistDetails['images'].isNotEmpty) {
          final artistImageUrl = artistDetails['images'][0]['url'];
          return artistImageUrl;
        }
      }
    }
  }

  return 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
}