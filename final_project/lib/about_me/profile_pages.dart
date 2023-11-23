import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'about_me.dart';

class UserProfilePage extends StatelessWidget {
  final AboutData userData;

  UserProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userData.name),
      ),
      body: Center(
        child: Text('Profile of ${userData.name}'),
      ),
    );
  }
}
