import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/db_utils.dart';

Future<List<Map<String, dynamic>>> fetchLastFmTracks() async {
  final prefs = await SharedPreferences.getInstance();
  final String? currentUser = prefs.getString('username');

  if (currentUser == null) {
    throw Exception('No current user found');
  }

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String? lastFmUsername = await _databaseHelper.getLastFmUsername(currentUser);

  // If the user has not connected their Last.fm account, throw an exception
  if (lastFmUsername == null) {
    throw Exception('Last.fm username not found for current user');
  }

  final apiKey = dotenv.get('API_KEY');

  final response = await http.get(
    Uri.parse('https://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=$lastFmUsername&api_key=$apiKey&format=json&limit=10'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print('API Response: $data');
    // If the API response is in the expected format, return the tracks
    if (data['recenttracks'] != null && data['recenttracks']['track'] != null) {
      final tracks = List<Map<String, dynamic>>.from(data['recenttracks']['track']);
      final tracksWithPlaycount = tracks
          .where((track) => track.containsKey('playcount') && track['playcount'] != null)
          .toList();

      return tracksWithPlaycount;
    } else {
      throw Exception('Unexpected data format in the API response');
    }
  } else {
    throw Exception('Failed to fetch data: ${response.statusCode}');
  }
}