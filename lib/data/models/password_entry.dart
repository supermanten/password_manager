class PasswordEntry {
  final int? id;
  final String website;
  final String username;
  final String password;

  PasswordEntry({
    this.id,
    required this.website,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'website': website,
      'username': username,
      'password': password,
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'] as int?,
      website: map['website'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
    );
  }
}
