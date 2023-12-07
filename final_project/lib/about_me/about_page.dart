import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/about_me/profile_pages.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../recent_tracks.dart';
import '../top_data/geo_top_tracks.dart';
import '../top_data/top_scrobbles.dart';
import '../top_data/top_visulized_data.dart';
import '../utils/app_drawer.dart';
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
            aboutData = AboutData.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
            _fetchData();
            fetchTopSongData();
            fetchArtistSongData();
            fetchTopAlbumData();
            fetchLastTrackData();
          });
        } else {
          setState(() {
            _promptForDataEntry();
          });
        }
      });
    }
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
    final topData = await fetchTopAlbum(aboutData!.lastFMUsername);
    setState(() {
      print(topData['URL']);
      topAlbum = (topData['topAlbum'] ?? '') + " - " + (topData['topArtist'] ?? '');
      imgAlbum = topData['URL'] ?? 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
    });
  }

  void _fetchData() async {
    if (aboutData != null) {
      int scrobbles = await fetchTotalScrobbles(aboutData!.lastFMUsername);
      setState(() {
        totalScrobbles = scrobbles;
      });
    }
  }

  void fetchTopSongData() async {
    if (aboutData != null) {
      final topData = await fetchTopSong(aboutData!.lastFMUsername);
      setState(() {
        topSong = (topData['topSong'] ?? '') + " - " + (topData['topArtist'] ?? '');
        imgSong = topData['URL'] ?? 'https://lastfm.freetls.fastly.net/i/u/64s/4128a6eb29f94943c9d206c08e625904.jpg';
      });
    }
  }


  void _promptForDataEntry() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DataEntryForm()));
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('username');

  }
  void _showListBottomSheet(BuildContext context, List<String> list, String title) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    title: Text(title),
                    onTap: () => Navigator.pop(context)
                ),
                for (var item in list) ListTile(title: Text(item)),
              ],
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profiles'),
        backgroundColor: Colors.black87,
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
      drawer: AppDrawer(
        getCurrentUser: () async {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getString('username');
        },
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
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: aboutData!.name,
                        style: Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: " (@" + aboutData!.username + ")",
                        style: Theme.of(context).textTheme.headline6?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Favorite Genre: " + aboutData!.favoriteGenre,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 5),
                Text(aboutData!.bio),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoCard('Followers: ${aboutData!.followers.length}', onTap: () {
                      _showListBottomSheet(context, aboutData!.followers, "Followers");
                    }),
                    _buildInfoCard('Following: ${aboutData!.following.length}', onTap: () {
                      _showListBottomSheet(context, aboutData!.following, "Following");
                    }),
                  ],
                ),
                SizedBox(height: 10),
                _buildInfoCard('Scrobbles: $totalScrobbles'),
                if (topSong.isNotEmpty) _buildDetailTile('Top Song', topSong, imgSong),
                if (topArtist.isNotEmpty) _buildDetailTile('Top Artist', topArtist, imgArtist),
                if (topArtist.isNotEmpty) _buildDetailTile('Top Album', topAlbum, imgAlbum),
                if (topArtist.isNotEmpty) _buildDetailTile('Recently Played', lastSong, imgLast),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String title, String detail, String imageUrl) {
    return GestureDetector(
        onTap: () {
          if (title == "Top Song") {
            print(aboutData!.lastFMUsername);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TopScrobblesPage(lastFmUsername: aboutData!.lastFMUsername, initialTabIndex: 0)),
            );

          } else if (title == "Top Artist") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TopScrobblesPage(lastFmUsername: aboutData!.lastFMUsername, initialTabIndex: 1)),
            );
          } else if (title == "Top Album") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TopScrobblesPage(lastFmUsername: aboutData!.lastFMUsername, initialTabIndex: 2)),
            );
          } else if(title == "Recently Played") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecentTracksPage(lastFmUsername: aboutData!.lastFMUsername)),
            );
          }
        },
        child: Container(
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
        ));
  }
  Widget _buildInfoCard(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16),
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
            var profilePicUrl = data['profilePicUrl'] ?? 'https://lastfm.freetls.fastly.net/i/u/avatar170s/818148bf682d429dc215c1705eb27b98.png';

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
