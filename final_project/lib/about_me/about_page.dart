import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/about_me/profile_pages.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../recent_tracks.dart';
import '../top_data/geo_top_tracks.dart';
import '../top_data/top_scrobbles.dart';
import '../top_data/top_visulized_data.dart';
import 'about_me.dart';
import 'data_entry_form.dart';

class AboutMePage extends StatefulWidget {
  @override
  _AboutMePageState createState() => _AboutMePageState();
}

class _AboutMePageState extends State<AboutMePage> {
  AboutData? aboutData;

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

  void _promptForDataEntry() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DataEntryForm()));
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('username');

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
            var profilePicUrl = data['profilePicUrl'] ?? 'default_profile_pic_url'; //TO:DO default profile pic

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

