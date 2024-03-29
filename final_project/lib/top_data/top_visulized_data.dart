import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../about_me/about_page.dart';
import '../utils/app_drawer.dart';
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
        showTitle: true,
      );
    })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualized Data'),
        backgroundColor: Colors.black87,
      ),
      drawer: AppDrawer(
        getCurrentUser: () async {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getString('username');
        },
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
    _topTracks.sort((a, b) {
      double playcountA = double.tryParse(a['playcount'] ?? '0') ?? 0;
      double playcountB = double.tryParse(b['playcount'] ?? '0') ?? 0;
      return playcountA.compareTo(playcountB);
    });
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
          pointColorMapper: (dynamic tracks, _) =>
          _topTracks.indexOf(tracks) % 2 == 0 ? Colors.green : Colors.red,
          dataLabelSettings: DataLabelSettings(
            isVisible: false,
            textStyle: TextStyle(
              fontSize: 12,
            ),
          ),
          enableTooltip: true,
          onPointTap: (ChartPointDetails details) {
            if(details.pointIndex != null) {
              _showTrackDetails(details.pointIndex!);
            }
          },
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

  void _showTrackDetails(int index) {
    if (index < 0 || index >= _topTracks.length) return;
    var track = _topTracks[index];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),
                Text(
                  "Name: ${track['name']}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  "Artist: ${track['artist']['name']}",
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  "Scrobbles: ${track['playcount']}",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildPieChart() {
    return GestureDetector(
      onTap: () {
        if (_topTracks.isNotEmpty) {
          _showSongDetails(_topTracks[0]);
        }
      },
      child: PieChart(
        PieChartData(
          sections: _getSections(),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, PieTouchResponse? touchResponse) {
              if (event is FlTapUpEvent) {
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
      ),
    );

  }



  Color _getColor(int index) {
    return Colors.accents[index % Colors.accents.length];
  }

  void _showSongDetails(dynamic track) async {
    if (track != null && _topTracks.contains(track)) {
      print('Showing song details for ${track['name']}');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          print('Building dialog for ${track['name']}');
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16),

                  Text(
                    "Name: ${track['name']}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Artist: ${track['artist']['name']}",
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Play Count: ${track['playcount']}",
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("OK"),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      print('Invalid track or track not in _topTracks');
    }
  }
}

enum ChartType {
  Bar,
  Pie,
}