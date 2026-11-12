import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/auth_widgets.dart';
import '../services/auth_service.dart';

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
  bool busy = false;
  String? error;

  Future<void> _login() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final account = await widget.state.auth.signIn(identity, password);
      if (mounted) widget.state.authenticated(account);
    } catch (failure) {
      if (mounted) setState(() => error = authErrorMessage(failure));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

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
          label: 'Email Address',
          icon: Icons.mail_outline,
          keyboard: TextInputType.emailAddress,
          onChanged: (value) => identity = value,
          validator: validateEmail,
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
        if (error != null) AuthError(message: error!),
        FilledButton(
          onPressed: busy ? null : _login,
          child: Text(busy ? 'Signing in...' : 'Login'),
        ),
        SocialAuthButtons(
          registration: false,
          state: widget.state,
          disabled: busy,
          onBusyChanged: (value) => setState(() => busy = value),
        ),
        TextButton(
          onPressed: () => widget.state.open('Registration'),
          child: const Text('New to the app? Register Now'),
        ),
        TextButton(
          onPressed: busy ? null : () => widget.state.open('Phone Login'),
          child: const Text('Sign in with phone OTP'),
        ),
      ],
    ),
  );
}
