import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/db_utils.dart'; // Make sure this path is correct

Future<List<Map<String, dynamic>>> fetchLastFmTracks() async {
  final prefs = await SharedPreferences.getInstance();
  final String? currentUser = prefs.getString('username');

  if (currentUser == null) {
    // Handle the situation where no current user is found
    throw Exception('No current user found');
  }

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String? lastFmUsername = await _databaseHelper.getLastFmUsername(currentUser);

  if (lastFmUsername == null) {
    // Handle the situation where no Last.fm username is found for the current user
    throw Exception('Last.fm username not found for current user');
  }

  final apiKey = dotenv.get('API_KEY'); // Assuming you still want to use dotenv for the API key

  final response = await http.get(
    Uri.parse('https://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=$lastFmUsername&api_key=$apiKey&format=json&limit=10'),
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