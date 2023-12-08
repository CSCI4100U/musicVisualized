import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:country_picker/country_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/fetch_image.dart';

const Color silverColor = Color(0xFFC0C0C0);
const Color goldColor = Color(0xFFFFD700);
const Color bronzeColor = Color(0xFFCD7F32);

class MostStreamedTracksPage extends StatefulWidget {
  @override
  _MostStreamedTracksPageState createState() => _MostStreamedTracksPageState();
}

class _MostStreamedTracksPageState extends State<MostStreamedTracksPage> {
  List<dynamic> _tracks = [];
  bool _isLoading = false;
  String _selectedCountry = 'Afghanistan';

  @override
  void initState() {
    super.initState();
    _determinePosition().then((countryName) {
      if (countryName != null) {
        setState(() {
          _selectedCountry = countryName;
        });
        displayTopTracks(_selectedCountry);
      }
    });
  }

  Future<String?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);
    return placemarks.first.country;
  }

  Future<List<dynamic>> fetchTopTracks(String country) async {
    final apiKey = dotenv.get('API_KEY');
    final response = await http.get(
      Uri.parse(
          'http://ws.audioscrobbler.com/2.0/?method=geo.getTopTracks&country=$country&api_key=$apiKey&format=json'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['tracks']['track'];
    } else {
      throw Exception('Failed to load top tracks');
    }
  }

  Future<String> fetchTrackImageUrl(String artist, String track) async {
    await dotenv.load();
    final accessToken = await getSpotifyAccessToken();

    final artistQueryParam = Uri.encodeQueryComponent(artist);
    final trackQueryParam = Uri.encodeQueryComponent(track);

    final searchUrl = Uri.parse(
        'https://api.spotify.com/v1/search?q=track:"$trackQueryParam" artist:"$artistQueryParam"&type=track&limit=1');

    final response = await http.get(searchUrl, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['tracks']['items'].isNotEmpty) {
        final trackImageUrl =
        data['tracks']['items'][0]['album']['images'][0]['url'];
        return trackImageUrl;
      }
    }

    // Handle error or return a default image URL
    return 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
  }

  void displayTopTracks(String country) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var tracks = await fetchTopTracks(country);
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
        title: Text('Top Tracks in $_selectedCountry'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showCountryPicker(
                context: context,
                showPhoneCode: false,
                onSelect: (Country country) {
                  setState(() {
                    _selectedCountry = country.name;
                    displayTopTracks(_selectedCountry);
                  });
                },
              );
            },
          ),
        ],
        backgroundColor: Colors.black87,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          var track = _tracks[index];

          // Determine size and outline color based on position
          double size = 50.0; // Default size
          Color outlineColor = Colors.transparent; // Default outline color
          if (index == 0) {
            size = 80.0; // Larger size for the first track
            outlineColor = goldColor; // Gold outline for the first track
          } else if (index == 1) {
            size = 70.0; // Slightly smaller size for the second track
            outlineColor =
                silverColor; // Silver outline for the second track
          } else if (index == 2) {
            size = 60.0; // Slightly smaller size for the third track
            outlineColor =
                bronzeColor; // Bronze outline for the third track
          }

          return FutureBuilder<String>(
            future: fetchTrackImageUrl(
              track['artist']['name'],
              track['name'],
            ),
            builder:
                (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                String imageUrl = snapshot.data ??
                    'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(
                      color: outlineColor,
                      width: 2.0,
                    ),
                  ),
                  elevation: 5,
                  margin:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        imageUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return Icon(Icons.broken_image);
                        },
                      ),
                    ),
                    title: Text(
                      track['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                        'Artist: ${track['artist']['name']}}'),

                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
