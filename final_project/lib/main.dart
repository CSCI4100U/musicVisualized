import 'package:final_project/top_data/top_visulized_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../account/login.dart';
import '../account/registration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final InitializationSettings initializationSettings =
  InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'));
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Landing Page',
      theme: ThemeData(
        backgroundColor: Colors.black87,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateLastActive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.clear();
    } else if (state == AppLifecycleState.resumed) {
      _updateLastActive();
      _checkAndScheduleNotification();
    }
  }

  void _updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastActive', DateTime.now().millisecondsSinceEpoch);
  }

  void _checkAndScheduleNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getInt('lastActive');
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastActive == null || now - lastActive > 259200000) { // 3 days in milliseconds
      _scheduleNotification();
    }
  }

  void _scheduleNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'engagement_channel', 'Engagement Channel',
        channelDescription: 'Channel for User Engagement',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false);
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'We miss you!',
        'Come back and check out new content.',
        platformChannelSpecifics);
  }

  void navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(toggleView: () => navigateToRegister(context)),
      ),
    );
  }

  void navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationPage(toggleView: () => navigateToLogin(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Text('Login'),
              onPressed: () => navigateToLogin(context),
            ),
            ElevatedButton(
              child: Text('Register'),
              onPressed: () => navigateToRegister(context),
            ),
          ],
        ),
      ),
    );
  }
}
