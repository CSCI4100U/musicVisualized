import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/about_me/profile_pages.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../recent_tracks.dart';
import '../top_data/geo_top_tracks.dart';
import '../top_data/top_scrobbles.dart';
import '../top_data/top_visulized_data.dart';
import '../utils/db_utils.dart';
import 'about_me.dart';
import 'data_entry_form.dart';

class AboutMePage extends StatefulWidget {
  @override
  _AboutMePageState createState() => _AboutMePageState();

}

class _AboutMePageState extends State<AboutMePage> {
  AboutData? aboutData;
  String topSong = '';
  String imgSong = '';
  String topArtist = '';
  String imgArtist = '';
  String topAlbum = '';
  String imgAlbum = '';
  String lastSong = '';
  String imgLast = '';
  int totalScrobbles = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchData();
    fetchTopSongData();
    fetchArtistSongData();
    fetchTopAlbumData();
    fetchLastTrackData();

  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('username');

    if (username != null) {
      FirebaseFirestore.instance.collection('aboutme')
          .where('username', isEqualTo: username.toLowerCase()).limit(5).get()
          .then((QuerySnapshot snapshot) {
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            aboutData = AboutData.fromMap(
                snapshot.docs.first.data() as Map<String, dynamic>);
          });
        } else {
          setState(() {
            _promptForDataEntry();
          });
        }
      });
    }
  }


  Future<void> _fetchData() async {
    int scrobbles = await fetchTotalScrobbles(aboutData!.lastFMUsername);
    setState(() {
      totalScrobbles = scrobbles;
    });
  }

  void fetchTopSongData() async {
    final topData = await fetchTopSong(aboutData!.lastFMUsername);
    setState(() {
      print(topData['URL']);
      topSong = (topData['topSong'] ?? '') + " - " + (topData['topArtist'] ?? '');
      imgSong = topData['URL'] ?? 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
    });
  }

  void fetchLastTrackData() async {
    final topData = await fetchLastTrack(aboutData!.lastFMUsername);
    setState(() {
      print(topData['URL']);
      lastSong = (topData['track'] ?? '') + " - " + (topData['artist'] ?? '');
      imgLast = topData['URL'] ?? 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
    });

  }

  void fetchArtistSongData() async {
    final topData = await fetchTopArtist(aboutData!.lastFMUsername);
    setState(() {
      topArtist = topData['topArtist'] ?? '';
      imgArtist = topData['URL'] ?? 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
    });
  }

  void fetchTopAlbumData() async {
    print(aboutData!.lastFMUsername);
    final topData = await fetchTopAlbum(aboutData!.lastFMUsername);
    setState(() {
      print(topData['URL']);
      topAlbum = (topData['topAlbum'] ?? '') + " - " + (topData['topArtist'] ?? '');
      imgAlbum = topData['URL'] ?? 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
    });
  }



  void _promptForDataEntry() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DataEntryForm()));
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('username');

  }

  Widget _buildDetailTile(String title, String detail, String imageUrl) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          imageUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),
          )
              : Icon(Icons.person, color: Colors.deepPurple, size: 30),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Me'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProfileSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: aboutData == null
          ? Center(child: CircularProgressIndicator())
          : _buildProfileView(),
      drawer: _buildDrawer(),
    );
  }


  Widget _buildDrawer() {
    return Drawer(
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
    );
  }


  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _TopGradientSection(userData: aboutData!),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  aboutData!.name,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  aboutData!.favoriteGenre,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 5),
                Text(aboutData!.bio),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoCard('Followers: ${aboutData!.followers.length}'),
                    _buildInfoCard('Following: ${aboutData!.following.length}'),

                  ],
                ),
              ],
            ),
          ),
          if (topSong.isNotEmpty) _buildDetailTile('Top Song', topSong, imgSong),
          if (topArtist.isNotEmpty) _buildDetailTile('Top Artist', topArtist, imgArtist),
          if (topArtist.isNotEmpty) _buildDetailTile('Top Album', topAlbum, imgAlbum),
          if (topArtist.isNotEmpty) _buildDetailTile('Recently Played', lastSong, imgLast),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }



}
class ProfileSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) return Container();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('aboutme')
          .orderBy('username')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        var docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            var profilePicUrl = data['profilePicUrl'] ?? 'https://lastfm.freetls.fastly.net/i/u/avatar170s/818148bf682d429dc215c1705eb27b98.png'; //TO:DO default profile pic

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(profilePicUrl),
                radius: 24,
              ),
              title: Text(data['name'] + " (@" + data['username'] + ")"),
              subtitle: Text(data['bio']),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(userData: AboutData.fromMap(data)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }



  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
class _TopGradientSection extends StatelessWidget {
  final AboutData userData;

  _TopGradientSection({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(userData.profilePicUrl),
      ),
    );
  }
}

