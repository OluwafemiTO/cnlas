import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _key = "jwt_token";
  final _key2 = "details";
  final _storage = const FlutterSecureStorage();

  /// Save JWT securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
  }

  /// Save JWT securely
  Future<void> saveDetailsInput(bool done) async {
    await _storage.write(key: _key2, value: done.toString());
  }

  /// Retrieve JWT
  Future<String?> getToken() async {
    return await _storage.read(key: _key);
  }

  /// Retrieve JWT
  Future<String?> getDetailsInput() async {
    return await _storage.read(key: _key2);
  }

  /// Delete JWT (logout)
  Future<void> clearToken() async {
    await _storage.delete(key: _key);
  }

  /// Check if token is expired
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );
      final exp = payload['exp'] as int?;
      if (exp == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= exp;
    } catch (e) {
      return true; // treat invalid tokens as expired
    }
  }
}
