import 'package:flutter/material.dart';

class AppTheme {
  static const Color sageGreen = Color(0xFFA8BDB0);
  static const Color lightBeige = Color(0xFFF5F0E1);
  static const Color softBrown = Color(0xFFC1A783);
  static const Color offWhite = Color(0xFFFAFAF5);

  static ThemeData lightTheme = ThemeData(
    primaryColor: sageGreen,
    scaffoldBackgroundColor: lightBeige,
    cardColor: offWhite,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: softBrown, fontSize: 16),
      bodyMedium: TextStyle(color: softBrown, fontSize: 14),
      headlineSmall: TextStyle(color: softBrown, fontWeight: FontWeight.bold, fontSize: 20),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: sageGreen,
        foregroundColor: offWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: sageGreen,
      foregroundColor: offWhite,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: offWhite,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primaryColor: sageGreen,
    scaffoldBackgroundColor: const Color(0xFF2A2F2B),
    cardColor: const Color(0xFF3C403A),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightBeige, fontSize: 16),
      bodyMedium: TextStyle(color: lightBeige, fontSize: 14),
      headlineSmall: TextStyle(color: lightBeige, fontWeight: FontWeight.bold, fontSize: 20),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: sageGreen,
        foregroundColor: offWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: sageGreen,
      foregroundColor: offWhite,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFF3C403A),
    ),
  );
}

