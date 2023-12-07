import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../about_me/about_page.dart';
import '../utils/db_utils.dart';
import 'top_scrobbles.dart';
import '../recent_tracks.dart';
import 'geo_top_tracks.dart';

class VisualizedDataPage extends StatefulWidget {
  @override
  _VisualizedDataPageState createState() => _VisualizedDataPageState();
}

class _VisualizedDataPageState extends State<VisualizedDataPage> {
  List<dynamic> _topTracks = [];
  bool _isDialogShown = false;
  ChartType _selectedChartType = ChartType.Bar;

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
      return;
    }

    final String? lastFmUsername =
    await _databaseHelper.getLastFmUsername(currentUser);
    if (lastFmUsername == null) {
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
        backgroundColor: Colors.black87,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black87,
              ),
              child: FutureBuilder<String?>(
                future: getCurrentUser(),
                builder: (BuildContext context,
                    AsyncSnapshot<String?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      return Text(
                        "Welcome, " + snapshot.data!,
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
                  MaterialPageRoute(
                      builder: (context) => MostStreamedTracksPage()),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton<ChartType>(
              value: _selectedChartType,
              items: [
                DropdownMenuItem<ChartType>(
                  value: ChartType.Bar,
                  child: Text('Bar Chart'),
                ),
                DropdownMenuItem<ChartType>(
                  value: ChartType.Pie,
                  child: Text('Pie Chart'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedChartType = value!;
                });
              },
            ),
            Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              height: 600,
              child: _selectedChartType == ChartType.Bar
                  ? _buildBarChart()
                  : _buildPieChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return SfCartesianChart(
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
          yValueMapper: (dynamic tracks, _) =>
          double.tryParse(tracks['playcount'] ?? '0') ?? 0,
          dataLabelSettings: DataLabelSettings(
            isVisible: false,
            textStyle: TextStyle(
              fontSize: 12,
            ),
          ),
          enableTooltip: true,
        ),
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        canShowMarker: false,
        format: 'point.y',
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: _getSections(),
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, PieTouchResponse? touchResponse) {
            if (event is FlLongPressEnd) {
              if (touchResponse != null &&
                  touchResponse.touchedSection != null) {
                _showSongDetails(
                  _topTracks[touchResponse.touchedSection!.touchedSectionIndex],
                );
              }
            }
          },
        ),
      ),
    );
  }




  List<PieChartSectionData> _getSections() {
    double totalPlayCount = _topTracks.fold(0.0, (sum, track) {
      return sum + (double.tryParse(track['playcount'] ?? '0') ?? 0);
    });

    return _topTracks
        .asMap()
        .entries
        .map((entry) {
      final int index = entry.key;
      final dynamic track = entry.value;

      double value = (double.tryParse(track['playcount'] ?? '0') ?? 0);
      double percent = (value / totalPlayCount) * 100;

      return PieChartSectionData(
        color: _getColor(index),
        value: percent,
        title: '${percent.toStringAsFixed(2)}%',
        radius: 60,
        titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Color _getColor(int index) {
    return Colors.accents[index % Colors.accents.length];
  }

  void _showSongDetails(dynamic track) {
    // Ensure that the index is within the valid range
    if (track != null && _topTracks.contains(track)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Song Details"),
            content: Column(
              children: [
                Text("Name: ${track['name']}"),
                Text("Play Count: ${track['playcount']}"),
              ],
            ),
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
  }
}


  enum ChartType {
  Bar,
  Pie,
}
