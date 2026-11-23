import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hr/main.dart' as hr;
import 'package:material_ui/material_ui.dart';

import 'app.dart' as employee;
import 'theme.dart';

class CareerConnectApp extends StatelessWidget {
  const CareerConnectApp({super.key, this.signedInChanges});

  final Stream<bool>? signedInChanges;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Career Connect',
    debugShowCheckedModeBanner: false,
    theme: employeeTheme(),
    home: _ChooseRole(signedInChanges: signedInChanges),
  );
}

enum _Role { employee, employer }

class _ChooseRole extends StatelessWidget {
  const _ChooseRole({this.signedInChanges});

  final Stream<bool>? signedInChanges;

  void _open(BuildContext context, _Role role) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _RoleFlow(role: role, signedInChanges: signedInChanges),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F7FF),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_rounded, color: Color(0xFF0069E8)),
                    SizedBox(width: 8),
                    Text(
                      'Career Connect',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text.rich(
                  TextSpan(
                    text: 'Find jobs or\n',
                    children: [
                      TextSpan(
                        text: 'hire talent',
                        style: TextStyle(color: Color(0xFF0069E8)),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0C2049),
                    fontSize: 40,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1.8,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/onboarding_wave.png',
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Image.asset(
                            'assets/images/onboarding_people.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'How would you like to continue?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth >= 300 &&
                        MediaQuery.textScalerOf(context).scale(16) <= 22;
                    final width = columns
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _RoleCard(
                          width: width,
                          featured: true,
                          onPressed: () => _open(context, _Role.employee),
                          icon: Icons.person_outline,
                          label: 'Employee / Job Seeker',
                          description: 'Browse jobs and apply',
                        ),
                        _RoleCard(
                          width: width,
                          onPressed: () => _open(context, _Role.employer),
                          icon: Icons.business_outlined,
                          label: 'HR / Employer',
                          description: 'Post jobs and review applicants',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.width,
    required this.label,
    required this.description,
    required this.icon,
    required this.onPressed,
    this.featured = false,
  });

  final double width;
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF005BC9);
    final foreground = featured ? Colors.white : const Color(0xFF0C2049);
    return SizedBox(
      width: width,
      child: Material(
        color: featured ? blue : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFCFE1FA)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Semantics(
            button: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE9F3FF),
                    foregroundColor: blue,
                    child: Icon(icon),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: foreground),
                  ),
                  const SizedBox(height: 10),
                  Icon(Icons.arrow_forward, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleFlow extends StatefulWidget {
  const _RoleFlow({required this.role, this.signedInChanges});

  final _Role role;
  final Stream<bool>? signedInChanges;

  @override
  State<_RoleFlow> createState() => _RoleFlowState();
}

class _RoleFlowState extends State<_RoleFlow> {
  final navigatorKey = GlobalKey<NavigatorState>();
  late final firebaseAuth = Firebase.apps.isEmpty
      ? null
      : FirebaseAuth.instance;
  late final signedInChanges =
      widget.signedInChanges ??
      firebaseAuth?.authStateChanges().map((user) => user != null);

  Widget _handleBack(BuildContext context, Widget? navigator) =>
      NavigatorPopHandler<void>(
        onPopWithResult: (_) => navigatorKey.currentState?.maybePop(),
        child: navigator!,
      );

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
    stream: signedInChanges,
    initialData: firebaseAuth?.currentUser != null,
    builder: (context, snapshot) =>
        PopScope<void>(canPop: snapshot.data != true, child: _roleApp()),
  );

  Widget _roleApp() => switch (widget.role) {
    // HR replaces its navigation stack after signing in and out.
    // Keep those changes inside the selected flow.
    _Role.employee => employee.MyApp(
      navigatorKey: navigatorKey,
      builder: _handleBack,
    ),
    _Role.employer => hr.MyApp(
      navigatorKey: navigatorKey,
      builder: _handleBack,
    ),
  };
}
