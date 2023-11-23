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
          .where('username', isEqualTo: username).limit(1).get()
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
        automaticallyImplyLeading: false,
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
      endDrawer: _buildDrawer(),
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            CircleAvatar(
              backgroundImage: NetworkImage(aboutData!.profilePicUrl),
              radius: 60,
              backgroundColor: Colors.deepPurple.shade50,
            ),
            SizedBox(height: 20),
            Text(
              aboutData!.name,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 15),
            _buildInfoCard('Favorite Genre: ${aboutData!.favoriteGenre}'),
            _buildInfoCard('Bio: ${aboutData!.bio}'),
            _buildInfoCard('Followers: ${aboutData!.followers.length}'),
            _buildInfoCard('Following: ${aboutData!.following.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
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
            return ListTile(
              title: Text(data['username']),
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

