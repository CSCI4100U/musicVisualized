import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<List<Map<String, dynamic>>> fetchLastFmTracks() async {
  final apiKey = dotenv.get('API_KEY');
  final user = dotenv.get('USER');

  final response = await http.get(
    Uri.parse('https://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=$user&api_key=$apiKey&format=json&limit=10'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print('API Response: $data');

    if (data['recenttracks'] != null && data['recenttracks']['track'] != null) {
      final tracks = List<Map<String, dynamic>>.from(data['recenttracks']['track']);
      final tracksWithPlaycount = tracks
          .where((track) => track.containsKey('playcount') && track['playcount'] != null)
          .toList();

      return tracksWithPlaycount;
    } else {
      // Handle unexpected data structure
      throw Exception('Unexpected data format in the API response');
    }
  } else {
    // Handle non-200 HTTP status codes
    throw Exception('Failed to fetch data: ${response.statusCode}');
  }
}