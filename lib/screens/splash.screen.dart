import 'package:cnlas/screens/inputDetails.screen.dart';
import 'package:flutter/material.dart';
import 'package:cnlas/apiService/auth.api.dart';
import 'package:cnlas/util/authService.util.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final AuthAPI _authApi = AuthAPI();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // Then use it like this
  Future<void> _checkAuth() async {
    try {
      final token = await _authService.getToken();

      if (token != null && !_authService.isTokenExpired(token)) {
        final user = await _authApi.getDetails();
        
        if (user.role == 'LECTURER') {
          final detailsInput = await _authService.getDetailsInput();
          
          if (detailsInput == 'true') {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => InputDetailsScreen(
                  email: user.email,
                  name: user.name,
                ),
              ),
            );
          }
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Auth check error: $e');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
