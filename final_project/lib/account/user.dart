class User {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String dob;
  final String lastfmuser;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.lastfmuser,
  });

  String getUsername() {
    return username;
  }

  User.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        username = res["username"],
        email = res["email"],
        password = res["password"],
        firstName = res["firstName"],
        lastName = res["lastName"],
        dob = res["dob"],
        lastfmuser = res["lastfmuser"];

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'password': password,
    'firstName': firstName,
    'lastName': lastName,
    'dob': dob,
    'lastfmuser': lastfmuser,
  };
}
