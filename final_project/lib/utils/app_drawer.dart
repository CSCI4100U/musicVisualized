import 'package:flutter/material.dart';
import '../about_me/about_page.dart';
import '../about_me/feed_page.dart';
import '../recent_tracks.dart';
import '../top_data/geo_top_tracks.dart';
import '../top_data/top_scrobbles.dart';
import '../top_data/top_visulized_data.dart';

class AppDrawer extends StatelessWidget {
  final Future<String?> Function() getCurrentUser;

  AppDrawer({required this.getCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black87,
            ),
            child: FutureBuilder<String?>(
              future: getCurrentUser(),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Text(
                    snapshot.hasData ? "Welcome, ${snapshot.data!}" : 'Guest',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
          _buildDrawerItem(
            icon: Icons.music_note,
            text: 'Top Scrobbles',
            onTap: () => _navigateTo(context, TopScrobblesPage()),
          ),
          _buildDrawerItem(
            icon: Icons.history,
            text: 'Recent Tracks',
            onTap: () => _navigateTo(context, RecentTracksPage()),
          ),
          _buildDrawerItem(
            icon: Icons.language,
            text: 'Top Tracks by Country',
            onTap: () => _navigateTo(context, MostStreamedTracksPage()),
          ),
          _buildDrawerItem(
            icon: Icons.bar_chart,
            text: 'Data Visualized',
            onTap: () => _navigateTo(context, VisualizedDataPage()),
          ),
          _buildDrawerItem(
            icon: Icons.people,
            text: 'Profiles',
            onTap: () => _navigateTo(context, AboutMePage()),
          ),
          _buildDrawerItem(
            icon: Icons.feed,
            text: 'Feed',
            onTap: () => _navigateTo(context, FeedPage()),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
