import 'package:material_ui/material_ui.dart';

import 'theme.dart';
import 'employee_shell.dart';
import 'services/auth_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialPage = 'Login',
    this.auth,
    this.navigatorKey,
    this.builder,
  });
  final String initialPage;
  final AuthService? auth;
  final GlobalKey<NavigatorState>? navigatorKey;
  final TransitionBuilder? builder;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Career Connect',
    navigatorKey: navigatorKey,
    builder: builder,
    debugShowCheckedModeBanner: false,
    theme: employeeTheme(),
    home: EmployeeShell(initialPage: initialPage, auth: auth),
  );
}
