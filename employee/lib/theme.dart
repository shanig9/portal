import 'package:flutter/material.dart';

const blue = Color(0xFF087DF1);

const ink = Color(0xFF14243C);
const paleBlue = Color(0xFFEAF6FF);

ThemeData employeeTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: blue).copyWith(
    primary: blue,
    secondary: const Color(0xFF399FD8),
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFFFAFDFF),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: ink, fontSize: 13, height: 1.4),
    bodyLarge: TextStyle(color: ink, fontSize: 14),
    titleMedium: TextStyle(
      color: ink,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFAFDFF),
    foregroundColor: ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF3FAFF),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    prefixIconColor: const Color(0xFF399FD8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDFEBF3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDFEBF3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: blue),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF399FD8),
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 46),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      minimumSize: const Size(0, 42),
      side: const BorderSide(color: Color(0xFFDCEAF5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE0EBF7)),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFF5FBFF),
    selectedColor: const Color(0xFFD9F0FF),
    labelStyle: const TextStyle(fontSize: 11, color: ink),
    side: const BorderSide(color: Color(0xFFDFEBF3)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    showCheckmark: false,
    padding: const EdgeInsets.symmetric(horizontal: 4),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    indicatorColor: const Color(0xFFDFF3FF),
    height: 68,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 10,
        color: states.contains(WidgetState.selected) ? blue : ink,
      ),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE6EFF6), thickness: 1),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: blue,
    linearTrackColor: Color(0xFFDCEBF5),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
);
