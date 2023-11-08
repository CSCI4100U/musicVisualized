import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String> fetchAlbumImageUrl(String artist, String track) async {
  await dotenv.load();
  final apiKey = dotenv.get('API_KEY');
  final response = await http.get(Uri.parse(
      'https://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=$apiKey&artist=${Uri.encodeComponent(artist)}&track=${Uri.encodeComponent(track)}&format=json'
  ));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final albumImageUrl = data['track']['album']['image'][1]['#text']; // Get the largest image
    return albumImageUrl;
  } else {
    // Handle error or return a default image URL
    return 'default_image_url';
  }
}
