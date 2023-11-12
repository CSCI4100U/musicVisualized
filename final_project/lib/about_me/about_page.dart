import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      FirebaseFirestore.instance.collection('aboutme').where(
          'username', isEqualTo: username).limit(1).get().then((
          QuerySnapshot snapshot) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Me'),
        backgroundColor: Colors.deepPurple, // Modern color for AppBar
        elevation: 0,
      ),
      body: aboutData == null
          ? Center(child: CircularProgressIndicator())
          : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Center( // Wrap the Column with a Center widget
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // Center content vertically
          crossAxisAlignment: CrossAxisAlignment.center,
          // Center content horizontally
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
        textAlign: TextAlign.center, // Center text inside the card
      ),
    );
  }
}