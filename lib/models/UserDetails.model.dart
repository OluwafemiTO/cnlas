class UserDetails {
  final String role;
  final String name;
  final String email;

  UserDetails({
    required this.role,
    required this.name,
    required this.email,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      role: json['role'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}