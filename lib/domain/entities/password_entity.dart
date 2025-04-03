class PasswordEntity {
  final int? id;
  final String website;
  final String username;
  final String password;

  PasswordEntity({
    this.id,
    required this.website,
    required this.username,
    required this.password,
  });
}
