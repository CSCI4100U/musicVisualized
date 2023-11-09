import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:country_picker/country_picker.dart';
import 'package:geolocator/geolocator.dart';

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

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Location services are not enabled
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Permissions are denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // Permissions are permanently denied
    }

    // When we reach here, permissions are granted and we can continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    return placemarks.first.country; // Get the country name from the first Placemark
  }

  Future<List<dynamic>> fetchTopTracks(String country) async {
    final apiKey = dotenv.get('API_KEY'); // Replace with your actual Last.fm API key
    final response = await http.get(
      Uri.parse('http://ws.audioscrobbler.com/2.0/?method=geo.getTopTracks&country=$country&api_key=$apiKey&format=json'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['tracks']['track']; // Adjust according to the actual JSON structure
    } else {
      // Handle error here
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
      // Handle errors
      setState(() {
        _isLoading = false;
      });
      // Consider showing an error message or a retry option to the user
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
                showPhoneCode: false, // Not necessary for country picker
                onSelect: (Country country) {
                  setState(() {
                    _selectedCountry = country.name;
                    displayTopTracks(_selectedCountry); // Load tracks for selected country
                  });
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          var track = _tracks[index]; // Adjust if the API structure is different
          return ListTile(
            title: Text(track['name']),
            subtitle: Text(track['artist']['name']),
            leading: Image.network(track['image'][0]['#text']), // Adjust the index for the desired image size
          );
        },
      ),
    );
  }
}
