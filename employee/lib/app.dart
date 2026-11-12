import 'package:flutter/material.dart';

import 'theme.dart';
import 'employee_shell.dart';
import 'services/auth_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialPage = 'Login', this.auth});
  final String initialPage;
  final AuthService? auth;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Career Connect',
    debugShowCheckedModeBanner: false,
    theme: employeeTheme(),
    home: EmployeeShell(initialPage: initialPage, auth: auth),
  );
}
