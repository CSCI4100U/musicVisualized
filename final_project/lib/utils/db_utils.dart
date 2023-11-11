import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../account/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<int> createUser(User user) async {
    final db = await instance.database;

    final id = await db.insert('users', user.toJson());
    print(id.toString() + db.path.toString());
    return id;
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
    CREATE TABLE users (
      id $idType,
      username $textType,
      email $textType,
      password $textType,
      firstName $textType,
      lastName $textType,
      dob $textType,
      lastfmuser $textType
      )
''');

    print("done");
  }



  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<bool> verifyUser(String username, String password) async {
    final db = await instance.database;

    // Hash the password. In a real-world application, you would salt it as well

    // Query the database for the username
    final result = await db.query(
      'users',
      columns: ['username', 'password'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      // Compare the stored hashed password with the hashed version of the input password
      return result.first['password'] == password;
    }

    // If the user was not found or the password did not match, return false
    return false;
  }

  Future<String?> getLastFmUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['lastfmuser'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return result.first['lastfmuser'] as String?;
    } else {
      return null;
    }
  }


  Future<void> deleteDB() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'users.db');

    await deleteDatabase(path);
    print('Database deleted');
  }


}
