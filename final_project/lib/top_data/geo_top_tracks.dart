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
          return Container(
            margin: EdgeInsets.all(8.0),
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: Text(
                track['name'],
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(track['artist']['name']),
              leading: Container(
                width: 80.0,
                height: 80.0,
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
