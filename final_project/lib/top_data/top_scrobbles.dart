import 'package:final_project/top_data/geo_top_tracks.dart';
import 'package:final_project/top_data/top_visulized_data.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:final_project/utils/fetch_image.dart';

import '../recent_tracks.dart';

class TopScrobblesPage extends StatefulWidget {
  @override
  _TopScrobblesPageState createState() => _TopScrobblesPageState();
}

class _TopScrobblesPageState extends State<TopScrobblesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _topTracks = [];
  List<dynamic> _topAlbums = [];
  List<dynamic> _topArtists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
    _fetchTopTrackScrobbles();
    _fetchTopAlbumsScrobles();
    _fetchTopArtistsScrobles();
  }

  void _fetchTopTrackScrobbles() async {
    await _fetchTopTracks();
  }

  void _fetchTopAlbumsScrobles() async {
    await _fetchTopAlbums();
  }

  void _fetchTopArtistsScrobles() async {
    await _fetchTopArtists();
  }

  Future<void> _fetchTopArtists() async {
    final String _apiKey = dotenv.get('API_KEY');
    final String _user = dotenv.get('USER');
    final response = await http.get(
      Uri.parse(
          'https://ws.audioscrobbler.com/2.0/?method=user.getTopArtists&user=$_user&api_key=$_apiKey&format=json&limit=10'
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _topArtists = data['topartists']['artist'];
      });


    }



  }

  Future<void> _fetchTopAlbums() async {
    final String _apiKey = dotenv.get('API_KEY');
    final String _user = dotenv.get('USER');
    final response = await http.get(
      Uri.parse(
          'https://ws.audioscrobbler.com/2.0/?method=user.getTopAlbums&user=$_user&api_key=$_apiKey&format=json&limit=10'
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _topAlbums = data['topalbums']['album'];
      });
    }

  }

  Future<void> _fetchTopTracks() async {
    final String _apiKey = dotenv.get('API_KEY');
    final String _user = dotenv.get('USER');
    final response = await http.get(
      Uri.parse(
          'https://ws.audioscrobbler.com/2.0/?method=user.getTopTracks&user=$_user&api_key=$_apiKey&format=json&limit=10'
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _topTracks = data['toptracks']['track'];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Scrobbles'),
        actions: <Widget>[

          // The Builder is used here to provide a context below the Scaffold
          Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); // This will open the end drawer
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tracks'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
          ],
        ),
        backgroundColor: Colors.black87,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_topTracks),
          _buildList(_topAlbums),
          _buildArtistList(_topArtists),
        ],
      ),
      // Here is the endDrawer added to your existing Scaffold
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Navigation Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.music_note),
              title: Text('Top Scrobbles'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Navigate to TopScrobblesPage or refresh the page if needed
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Recent Tracks'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RecentTracksPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('Top Tracks by Country'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MostStreamedTracksPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('Data Visualized'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => VisualizedDataPage()),
                );
              },
            ),
            // Add more ListTiles for other navigation options
          ],
        ),
      ),
    );
  }


  Widget _buildList(List<dynamic> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        var item = items[index];
        String artistName = item['artist']['name'] ?? 'Unknown Artist';
        String trackName = item['name'] ?? 'Unknown Track';
        String playCount = item['playcount']?.toString() ?? '0';
        if (items == _topAlbums){
          return FutureBuilder(

            future: fetchAlbumImageUrl(artistName, trackName),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }  else {
                String imageUrl = snapshot.data ?? 'http://mcgodftw.dev/i/r2kyqb6k.png'; // Fallback URL in case of error
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image);
                        },
                      ),
                    ),
                    title: Text(
                      trackName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('Artist: $artistName\nPlay count: $playCount'),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {
                      },
                    ),
                  ),
                );
              }
            },
          );
        }
        else {
          return FutureBuilder(

            future: fetchTrackImageUrl(artistName, trackName),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                String imageUrl = snapshot.data ??
                    'http://mcgodftw.dev/i/r2kyqb6k.png'; // Fallback URL in case of error
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image);
                        },
                      ),
                    ),
                    title: Text(
                      trackName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                        'Artist: $artistName\nPlay count: $playCount'),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {},
                    ),
                  ),
                );
              }
            },
          );
        }
      },
    );
  }

  Widget _buildArtistList(List<dynamic> artists) {
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        var artist = artists[index];
        String artistName = artist['name'];
        String playCount = artist['playcount'].toString();

        return FutureBuilder<String>(
          future: fetchArtistImageUrl(artistName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While waiting for the image to load, you can display a loading indicator
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              // Handle errors, if any
              return Text('Error: ${snapshot.error}');
            } else {
              // Image is loaded; display it
              String artistImageUrl = snapshot.data ?? 'assets/default_artist.png'; // Use the artist's image URL

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 5,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      artistImageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image);
                      },
                    ),
                  ),
                  title: Text(
                    artistName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('Play count: $playCount'),
                  trailing: IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () {
                      // Handle artist-related actions here
                    },
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
