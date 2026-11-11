import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  String identity = '';
  String password = '';
  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: AuthLayout(
      state: widget.state,
      registration: false,
      children: [
        const Text(
          'Welcome Back!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Login to your account to continue',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey),
        ),
        const SizedBox(height: 24),
        AuthField(
          label: 'Email or Mobile Number',
          icon: Icons.mail_outline,
          onChanged: (value) => identity = value,
          validator: validateIdentity,
        ),
        AuthField(
          label: 'Password',
          icon: Icons.lock_outline,
          password: true,
          onChanged: (value) => password = value,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => widget.state.open('Forgot Password'),
            child: const Text('Forgot Password?'),
          ),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) widget.state.showHome();
          },
          child: const Text('Login'),
        ),
        const SocialAuthButtons(registration: false),
        TextButton(
          onPressed: () => widget.state.open('Registration'),
          child: const Text('New to the app? Register Now'),
        ),
        TextButton(
          onPressed: widget.state.showHome,
          child: const Text('Explore the preview'),
        ),
      ],
    ),
  );
}
