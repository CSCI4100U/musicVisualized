import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about_me.dart';

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
      FirebaseFirestore.instance.collection('aboutme').where('username', isEqualTo: username).limit(1).get().then((QuerySnapshot snapshot) {
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            aboutData = AboutData.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Me'),
      ),
      body: aboutData == null ? CircularProgressIndicator() : SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              backgroundImage: NetworkImage(aboutData!.profilePicUrl),
              radius: 50,
            ),
            SizedBox(height: 20),
            Text(aboutData!.name, style: TextStyle(fontSize: 24)),
            SizedBox(height: 10),
            Text('Favorite Genre: ${aboutData!.favoriteGenre}'),
            SizedBox(height: 10),
            Text('Bio: ${aboutData!.bio}'),
          ],
        ),
      ),
    );
  }
}
