import 'package:final_project/top_data/geo_top_tracks.dart';
import 'package:final_project/top_data/top_visulized_data.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:final_project/utils/fetch_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../about_me/about_page.dart';
import '../utils/db_utils.dart';
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
  bool _isDialogShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
    _fetchData();
  }
  void _showScrobbleDialog() {
    if (!_isDialogShown) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Welcome"),
          content: Text("This is the Scrobble Data Page."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                _showScrobble2Dialog();
              },
            ),
          ],
        );
      },
    );
    _isDialogShown = true;
  }
  }
  void _showScrobble2Dialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Scrobble"),
          content: Text("Welcome to the Scrobble Page! Discover your music listening trends and explore personalized insights based on your track history."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  void _fetchData() async {
    await _fetchTopTracks();
    await _fetchTopAlbums();
    await _fetchTopArtists();
  }

  Future<void> _fetchTopArtists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? currentUser = prefs.getString('username');

      if (currentUser == null) {
        throw Exception('No current user found');
      }

      final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
      final String? lastFmUsername = await _databaseHelper.getLastFmUsername(currentUser);

      if (lastFmUsername == null) {
        throw Exception('Last.fm username not found for current user');
      }

      final String _apiKey = dotenv.get('API_KEY');
      final response = await http.get(
        Uri.parse(
            'https://ws.audioscrobbler.com/2.0/?method=user.getTopArtists&user=$lastFmUsername&api_key=$_apiKey&format=json&limit=10'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _topArtists = data['topartists']['artist'];
        });
        _showScrobbleDialog();
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
    }
  }

  Future<void> _fetchTopAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? currentUser = prefs.getString('username');
      if (currentUser == null) {
        throw Exception('No current user found');
      }

      final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
      final String? lastFmUsername = await _databaseHelper.getLastFmUsername(currentUser);
      if (lastFmUsername == null) {
        throw Exception('Last.fm username not found for current user');
      }

      final String _apiKey = dotenv.get('API_KEY');
      final response = await http.get(
        Uri.parse(
            'https://ws.audioscrobbler.com/2.0/?method=user.getTopAlbums&user=$lastFmUsername&api_key=$_apiKey&format=json&limit=10'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _topAlbums = data['topalbums']['album'];
        });
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {

    }
  }

  Future<void> _fetchTopTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? currentUser = prefs.getString('username');
      if (currentUser == null) {
        throw Exception('No current user found');
      }

      final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
      final String? lastFmUsername = await _databaseHelper.getLastFmUsername(currentUser);
      if (lastFmUsername == null) {
        throw Exception('Last.fm username not found for current user');
      }

      final String _apiKey = dotenv.get('API_KEY');
      final response = await http.get(
        Uri.parse(
            'https://ws.audioscrobbler.com/2.0/?method=user.getTopTracks&user=$lastFmUsername&api_key=$_apiKey&format=json&limit=10'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _topTracks = data['toptracks']['track'];
        });
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {

    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Scrobbles'),
        // automaticallyImplyLeading: false,

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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: FutureBuilder<String?>(
                future: getCurrentUser(),
                builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      );
                    } else {
                      return Text(
                        'Guest',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      );
                    }
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.music_note),
              title: Text('Top Scrobbles'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TopScrobblesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Recent Tracks'),
              onTap: () {
                Navigator.pop(context);
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
                Navigator.pop(context);
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
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => VisualizedDataPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('About Me'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AboutMePage()),
                );
              },
            ),
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
                String imageUrl = snapshot.data ?? 'http://mcgodftw.dev/i/r2kyqb6k.png';
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
                    'http://mcgodftw.dev/i/r2kyqb6k.png';
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
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              String artistImageUrl = snapshot.data ?? 'assets/default_artist.png';

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

Future<Map<String, String>> fetchTopSong(String lastFMUsername) async {
  await dotenv.load();
  final _apiKey = dotenv.get('API_KEY');

  final url = Uri.parse('http://ws.audioscrobbler.com/2.0/?method=user.gettoptracks&user=$lastFMUsername&api_key=$_apiKey&format=json');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final topTrack = data['toptracks']['track'][0];
      final topSong = topTrack['name'];
      final topArtist = topTrack['artist']['name'];
      final URL = await fetchTrackImageUrl(topArtist, topSong);
      print('uwu: ' + URL);
      return {
        'topSong': topSong,
        'topArtist': topArtist,
        'URL': URL
      };
    } else {
      print('Failed to fetch data: ${response.statusCode}');
      return {'topSong': 'Unavailable', 'topArtist': 'Unavailable'};
    }
  } catch (e) {
    print('Error occurred: $e');
    return {'topSong': 'Error', 'topArtist': 'Error'};
  }
}

Future<Map<String, String>> fetchTopArtist(String lastFMUsername) async {
  await dotenv.load();

  final _apiKey = dotenv.env['API_KEY'];

  final url = Uri.parse('http://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=$lastFMUsername&api_key=$_apiKey&format=json');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final topArtistData = data['topartists']['artist'][0];
      final topArtist = topArtistData['name'];
      final URL = await fetchArtistImageUrl(topArtist);

      return {
        'topArtist': topArtist,
        'URL': URL
      };
    } else {
      print('Failed to fetch data: ${response.statusCode}');
      return {'topArtist': 'Unavailable'};
    }
  } catch (e) {
    print('Error occurred: $e');
    return {'topArtist': 'Error'};
  }
}
