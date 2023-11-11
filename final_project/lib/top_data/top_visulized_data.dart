import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:final_project/utils/fetch_data.dart';
import 'package:final_project/utils/fetch_image.dart';
import '../utils/db_utils.dart';

class VisualizedDataPage extends StatefulWidget {
  @override
  _VisualizedDataPageState createState() => _VisualizedDataPageState();
}

class _VisualizedDataPageState extends State<VisualizedDataPage> {
  List<dynamic> _topTracks = [];

  @override
  void initState() {
    super.initState();
    _fetchTopTrackScrobbles();
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualized Data'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width,
                height: 600,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  enableAxisAnimation: true,
                  series: <BarSeries<dynamic, String>>[
                    BarSeries<dynamic, String>(
                      dataSource: _topTracks.cast<Map<String, dynamic>>(),
                      xValueMapper: (dynamic tracks, _) => tracks['name'].toString(),
                      yValueMapper: (dynamic tracks, _) => double.tryParse(tracks['playcount'] ?? '0') ?? 0,
                      dataLabelSettings: DataLabelSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}