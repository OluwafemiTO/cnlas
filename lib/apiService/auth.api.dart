import 'dart:convert';
import 'package:cnlas/config/config.dart';
import 'package:cnlas/models/UserDetails.model.dart';
import 'package:cnlas/models/user.model.dart';
import 'package:cnlas/util/authService.util.dart';
import 'package:http/http.dart' as http;


class AuthAPI {
  final String baseUrl = "${Config.baseUrl}/auth";
  final AuthService jwt = AuthService();

  Future<User> registerUser(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['data']["token"];

      jwt.saveToken(token);
      return User.fromJson(data['data']);
    } else {
      throw Exception("Failed to register: ${response.body}");
    }
  }

  Future<void> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['data']["token"];
      jwt.saveToken(token);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["error"] ?? "Login failed");
    }
  }

  Future<UserDetails> getDetails() async {
    final token = await jwt.getToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    final response = await http.get(
      Uri.parse("$baseUrl/role"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['success'] == true) {
        return UserDetails.fromJson(jsonResponse['data']);
      } else {
        throw Exception('Failed to get details');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to load details');
    }
  }

  Future<void> logout () async{
    jwt.clearToken();
  }
}
