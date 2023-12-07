import 'package:final_project/account/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/db_utils.dart';
import 'login.dart';

class RegistrationPage extends StatefulWidget {
  final VoidCallback toggleView;

  RegistrationPage({required this.toggleView});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController lastfmuserController = TextEditingController();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  DateTime? selectedDate; // Added to store the chosen date

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<bool> _isUsernameTaken(String username) async {
    try {
      final querySnapshot =
      await FirebaseFirestore.instance.collection('aboutme').get();

      final usernames = querySnapshot.docs
          .map((doc) => doc['username'].toString().toLowerCase())
          .toList();

      print('Fetched usernames from Firestore: $usernames');

      return usernames.contains(username.toLowerCase());
    } catch (e) {
      print("Error checking username: $e");
      return true;
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    lastfmuserController.dispose();
    super.dispose();
  }

  // Submit data to local SQLite database
  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final String username = usernameController.text;

      // Check if the username is already taken
      if (await _isUsernameTaken(username)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username is already taken. Please choose another one.')),
        );
        return;
      }

      User newUser = User(
        username: username,
        email: emailController.text,
        password: passwordController.text,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        dob: dobController.text,
        lastfmuser: lastfmuserController.text,
      );

      await _databaseHelper.createUser(newUser);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success!!!!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                } else if (!value.contains('@')) {
                  return 'Invalid email format';
                }
                return null;
              },
            ),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            TextFormField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            TextFormField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            TextFormField(
              controller: dobController,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                suffixIcon: Icon(Icons.date_range),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            TextFormField(
              controller: lastfmuserController,
              decoration: InputDecoration(labelText: 'LastFM Username'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Processing Data')),
                  );
                  _submitData();
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
