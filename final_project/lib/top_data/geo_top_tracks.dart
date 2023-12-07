import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:country_picker/country_picker.dart';
import 'package:geolocator/geolocator.dart';

const Color silverColor = Color(0xFFB0C4DE); // Adjusted silver color
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
          double size = 80.0; // Default size
          double outlineWidth = 2.0; // Default outline width
          Color outlineColor = Colors.transparent; // Default outline color

          if (index == 0) {
            size = 110.0; // Larger size for the first track
            outlineWidth = 4.0; // Bolder outline for the first track
            outlineColor = goldColor; // Gold outline for the first track
          } else if (index == 1) {
            size = 100.0; // Slightly smaller size for the second track
            outlineWidth = 3.0; // Bolder outline for the second track
            outlineColor = silverColor; // Updated silver outline color
          } else if (index == 2) {
            size = 95.0; // Slightly smaller size for the third track
            outlineWidth = 3.0; // Bolder outline for the third track
            outlineColor = bronzeColor; // Bronze outline for the third track
          }

          return Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: outlineColor,
                width: outlineWidth,
              ),
            ),
            child: ListTile(
              title: Text(
                track['name'],
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(track['artist']['name']),
              leading: Container(
                width: size,
                height: size,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    track['image'][0]['#text'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
