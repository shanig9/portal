import 'package:flutter/material.dart';

import 'theme.dart';
import 'employee_shell.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialPage = 'Login'});
  final String initialPage;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Career Connect',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: blue),
      scaffoldBackgroundColor: const Color(0xFFF5F9FF),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEDF5FE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0EBF7)),
        ),
      ),
    ),
    home: EmployeeShell(initialPage: initialPage),
  );
}
