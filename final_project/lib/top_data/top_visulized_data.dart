import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:final_project/utils/fetch_data.dart';


class VisualizedDataPage extends StatefulWidget {
  @override
  _VisualizedDataPageState createState() => _VisualizedDataPageState();
}

class _VisualizedDataPageState extends State<VisualizedDataPage> {
  List<Map<String, dynamic>> tracksData = [];

  @override
  void initState() {
    super.initState();
    _fetchLastFmData();
  }

  Future<void> _fetchLastFmData() async {
    try {
      final tracks = await fetchLastFmTracks();
      setState(() {
        tracksData = tracks;
      });
       // Print the data to the console
    } catch (e) {
      print('Error fetching Last.fm data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print("hi console");
    print(tracksData);
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualized Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width, // Adjust width as needed
              height: 300,

              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                enableAxisAnimation: true,
                series: <BarSeries<Map<String, dynamic>, String>>[
                  BarSeries<Map<String, dynamic>, String>(
                    dataSource: tracksData,

                    xValueMapper: ( tracks, _) => tracks['name'], // X-axis shows song names
                    yValueMapper: (tracks, _) => tracks['playcount'], // Y-axis shows play count
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}