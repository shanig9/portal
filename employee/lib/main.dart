import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
export 'app.dart' show MyApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _FirebaseStartup());
}

class _FirebaseStartup extends StatefulWidget {
  const _FirebaseStartup();
  @override
  State<_FirebaseStartup> createState() => _FirebaseStartupState();
}

class _FirebaseStartupState extends State<_FirebaseStartup> {
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
