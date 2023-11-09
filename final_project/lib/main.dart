import 'package:final_project/top_data/geo_top_tracks.dart';
import 'package:final_project/top_data/top_scrobbles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'recent_tracks.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last.FM Recently Played',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: MostStreamedTracksPage(),
      //TopScrobblesPage()
    );
  }
}
