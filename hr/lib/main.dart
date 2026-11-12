import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens.dart';
import 'auth_service.dart';
import 'auth_screens.dart' show companyForAccount;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseStartup());
}

class FirebaseStartup extends StatefulWidget {
  const FirebaseStartup({super.key});
  @override
  State<FirebaseStartup> createState() => _FirebaseStartupState();
}

class _FirebaseStartupState extends State<FirebaseStartup> {
  late Future<FirebaseApp> initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseApp>(
    future: initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return const MyApp();
      }
      return MaterialApp(
        title: 'Career Connect',
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Career Connect could not start. Please try again.',
                      ),
                      TextButton(
                        onPressed: () => setState(
                          () => initialization = Firebase.initializeApp(),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}

const brandBlue = Color(0xFF007AFF);
const ink = Color(0xFF10133F);

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.auth});
  final HrAuthService? auth;

  @override
  Widget build(BuildContext context) {
    final service = auth ?? FirebaseHrAuthService.instance;
    final account = service.currentAccount;
    return HrAuthScope(
      auth: service,
      child: MaterialApp(
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
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
        home: account == null
            ? const WelcomeScreen()
            : PortalScreen(company: companyForAccount(account)),
      ),
    );
  }
}
