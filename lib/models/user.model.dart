class User {
  User({
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      role: json['role'],
      token: json['token'],
    );
  }

  final String email;
  final String name;
  final String role;
  final String token;
}
