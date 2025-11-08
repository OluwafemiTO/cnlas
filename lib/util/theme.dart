import 'package:flutter/material.dart';

/// Central place for app theme data
class AppTheme {
  static const Color darkAccent = Color(0xFF9CA3AF); // Muted grey for icons/subtext
  static const Color darkBackground = Color(0xFF111827); // Scaffold background (near-black, not pure)
  static const Color darkBodyText = Color(0xFFD1D5DB); // Subtext/hint text, softer gray
  static const Color darkHeadingText = Color(0xFFF9FAFB); // Titles, bright white for contrast
  // Supporting colors
  static const Color darkInputFill = Color(0xFF1F2937); // TextField background (slightly lighter than scaffold)

  // Dark theme colors (matching your light palette)
  static const Color darkPrimary = Color(0xFF3B82F6); // Softer blue, still vibrant for CTAs

  // Dark ThemeData
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,

    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,   // buttons, highlights
      secondary: darkAccent,  // secondary actions/icons
      surface: Color(0xFF1E293B), // cards/surfaces (slightly lighter than scaffold)
      onPrimary: Colors.white,    // text on buttons
      onSurface: darkHeadingText, // main text
    ),

    // AppBar style
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkHeadingText,
      elevation: 0,
    ),

    // Input fields (TextField, TextFormField)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputFill,
      hintStyle: const TextStyle(color: darkBodyText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      prefixIconColor: darkBodyText,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );

  static const Color lightAccent = Color(0xFF6B7280);   // Muted grey for subtext/icons
  static const Color lightBackground = Color(0xFFF9FAFB); // Scaffold background (off-white)
  static const Color lightBodyText = Color(0xFF6B7280);      // Subtext + hint text
  static const Color lightHeadingText = Color(0xFF0A0D14);   // "Create Account" title
  // Supporting colors
  static const Color lightInputFill = Color(0xFFF5F8FC);     // TextField background

  // Light theme colors (matching the screenshot)
  static const Color lightPrimary = Color(0xFF007BFF);   // Bright blue (Sign Up button)

  // Light ThemeData
  static ThemeData lightTheme = ThemeData(
  useMaterial3: true, // enable M3 so it's future-proof
  brightness: Brightness.light,
  scaffoldBackgroundColor: lightBackground,

  colorScheme: const ColorScheme.light(
    primary: lightPrimary,   // buttons, highlights
    secondary: lightAccent,  // secondary actions/icons
    surface: Colors.white,   // cards/surfaces
    onPrimary: Colors.white, // text on buttons
    onSurface: lightHeadingText,  // main text
  ),

  // AppBar style
  appBarTheme: const AppBarTheme(
    backgroundColor: lightBackground,
    foregroundColor: lightHeadingText,
    elevation: 0,
  ),

  // Input fields (TextField, TextFormField)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: lightInputFill,
    hintStyle: const TextStyle(color: lightBodyText),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    prefixIconColor: lightBodyText,
  ),

  // Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
);
}
