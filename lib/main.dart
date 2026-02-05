import 'package:cnlas/screens/home.screen.dart';
import 'package:cnlas/screens/profile.screen.dart';
import 'package:flutter/material.dart';
import 'package:cnlas/util/theme.dart';
import 'package:cnlas/screens/login.screen.dart';
import 'package:cnlas/screens/signUp.screen.dart';
import 'package:cnlas/screens/splash.screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CNLAS',
      theme: AppTheme.lightTheme,       // Light mode
      darkTheme: AppTheme.darkTheme,    // Dark mode
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signUp': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => const ProfileScreen(),      },
    );
    
  }
}
