import 'package:cnlas/apiService/auth.api.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final authService = AuthAPI();

  Future<void> handleLogout() async {
    await authService.logout();
    
    if (!mounted) return; // Safety check
    
    // Remove all previous routes and go to login
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false, // This removes all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: handleLogout,
          child: const Text('Logout'),
        ),
      ),
    );
  }
}