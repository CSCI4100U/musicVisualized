import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/utils/db_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'about_page.dart';

class DataEntryForm extends StatefulWidget {
  @override
  _DataEntryFormState createState() => _DataEntryFormState();
}

class _DataEntryFormState extends State<DataEntryForm> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String favoriteGenre = '';
  String bio = '';
  String profilePicUrl = '';
  List followers = <String> [];
  List following = <String> [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Your Details"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Favorite Genre'),
                onSaved: (value) => favoriteGenre = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Bio'),
                onSaved: (value) => bio = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Profile Picture URL'),
                onSaved: (value) => profilePicUrl = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _saveUserData();
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Save the user's data to firestore
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('username');

    if (username != null) {
      final userRef = FirebaseFirestore.instance.collection('aboutme').doc();
      final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

      final String? lastFmUsername = await _databaseHelper.getLastFmUsername(username);

      await userRef.set({
        'username': username.toLowerCase(),
        'name': name,
        'favoriteGenre': favoriteGenre,
        'bio': bio,
        'profilePicUrl': profilePicUrl,
        'followers': List<String>.from(followers),
        'following': List<String>.from(following),
        'lastFMUsername': lastFmUsername,
      });
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AboutMePage()));
      }
    }
  }

}


