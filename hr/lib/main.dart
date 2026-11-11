import 'package:flutter/material.dart';

import 'screens.dart';

void main() => runApp(const MyApp());

const brandBlue = Color(0xFF007AFF);
const ink = Color(0xFF10133F);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Career Connect HR Portal',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: brandBlue),
      scaffoldBackgroundColor: const Color(0xFFF9FBFF),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF9FBFF),
        foregroundColor: ink,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFCBD6ED)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandBlue,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: brandBlue),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE6EEFC)),
        ),
      ),
    ),
    home: const WelcomeScreen(),
  );
}
