import 'package:flutter/material.dart'; // for general Flutter widgets and MaterialApp
import 'package:flutter_dotenv/flutter_dotenv.dart'; // for environment variables
import 'package:http/http.dart' as http; // for making HTTP requests
import 'dart:convert'; // for JSON processing
import 'package:shared_preferences/shared_preferences.dart'; // for local storage
import 'package:syncfusion_flutter_charts/charts.dart'; // for Syncfusion charts
import '../about_me/about_page.dart';
import '../utils/db_utils.dart';
import 'top_scrobbles.dart'; // Ensure you have this page
import '../recent_tracks.dart'; // Ensure you have this page
import 'geo_top_tracks.dart'; // Ensure you have this page


class VisualizedDataPage extends StatefulWidget {
  @override
  _VisualizedDataPageState createState() => _VisualizedDataPageState();
}

class _VisualizedDataPageState extends State<VisualizedDataPage> {
  List<dynamic> _topTracks = [];
  bool _isDialogShown = false;

  @override
  void initState() {
    super.initState();
    _fetchTopTrackScrobbles();

  }
  void _showVisualiseDialog() {
    if (!_isDialogShown) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Welcome"),
            content: Text("This is the Visualized Data Page."),
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
      _isDialogShown = true;
    }
  }

  void _fetchTopTrackScrobbles() async {

    await _fetchTopTracks();
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<void> _fetchTopTracks() async {
    final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    final String _apiKey = dotenv.get('API_KEY');

    final String? currentUser = await getCurrentUser();
    if (currentUser == null) {
      // Handle the situation where no current user is found.
      return;
    }

    final String? lastFmUsername = await _databaseHelper.getLastFmUsername(currentUser);
    if (lastFmUsername == null) {
      // Handle the situation where no lastfmusername is found for the given user.
      return;
    }

    final response = await http.get(
      Uri.parse(
        'https://ws.audioscrobbler.com/2.0/?method=user.getTopTracks&user=$lastFmUsername&api_key=$_apiKey&format=json&limit=20',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _topTracks = data['toptracks']['track'];
        _showVisualiseDialog();

      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualized Data'),
        // automaticallyImplyLeading: false,

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
      body: Center(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width,
                height: 600,
                child:Align(
                  alignment: Alignment.center,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(
                    labelStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                    labelPosition: ChartDataLabelPosition.inside,
                  ),
                  enableAxisAnimation: true,
                  series: <BarSeries<dynamic, String>>[
                    BarSeries<dynamic, String>(
                      dataSource: _topTracks.cast<Map<String, dynamic>>(),
                      xValueMapper: (dynamic tracks, _) => tracks['name'].toString(),
                      yValueMapper: (dynamic tracks, _) => double.tryParse(tracks['playcount'] ?? '0') ?? 0,
                      dataLabelSettings: DataLabelSettings(
                        isVisible: false,
                        textStyle: TextStyle(
                          fontSize: 12, // Set your desired font size
                        ),
                      ),
                      enableTooltip: true, // Enable tooltip for the bar series
                    ),
                  ],
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    header: '', // You can customize the header if needed
                    canShowMarker: false,
                    format: 'point.y', // You can customize the format of the tooltip content
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}