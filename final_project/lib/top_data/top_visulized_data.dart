import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:final_project/utils/fetch_data.dart';
import 'package:final_project/utils/fetch_image.dart';

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

  Future<void> _fetchTopTracks() async {
    final String _apiKey = dotenv.get('API_KEY');
    final String _user = dotenv.get('USER');
    final response = await http.get(
      Uri.parse(
        'https://ws.audioscrobbler.com/2.0/?method=user.getTopTracks&user=$_user&api_key=$_apiKey&format=json&limit=20',
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