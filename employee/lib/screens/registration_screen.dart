import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/auth_widgets.dart';
import '../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final form = GlobalKey<FormState>();
  String name = '', email = '', mobile = '', password = '';
  bool busy = false;
  String? error;

  Future<void> _register() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final account = await widget.state.auth.register(name, email, password);
      if (!mounted) return;
      widget.state.authenticated(account, onboarding: true);
      // A contact number is not a verified phone sign-in credential.
      widget.state.data['Mobile Number'] = mobile.trim();
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
      registration: true,
      children: [
        AuthField(
          label: 'Full Name',
          icon: Icons.person_outline,
          onChanged: (value) => name = value,
        ),
        AuthField(
          label: 'Email Address',
          icon: Icons.mail_outline,
          keyboard: TextInputType.emailAddress,
          onChanged: (value) => email = value,
          validator: (value) =>
              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                  .hasMatch(value?.trim() ?? '')
              ? null
              : 'Enter a valid email address',
        ),
        AuthField(
          label: 'Mobile Number',
          icon: Icons.phone_outlined,
          keyboard: TextInputType.phone,
          onChanged: (value) => mobile = value,
          validator: (value) =>
              RegExp(r'^\+?[\d\s-]{10,16}$').hasMatch(value?.trim() ?? '') &&
                  (value?.replaceAll(RegExp(r'\D'), '').length ?? 0) >= 10
              ? null
              : 'Enter a valid mobile number',
        ),
        AuthField(
          label: 'Password',
          icon: Icons.lock_outline,
          password: true,
          onChanged: (value) => password = value,
          validator: (value) =>
              (value?.length ?? 0) >= 8 ? null : 'Use at least 8 characters',
        ),
        AuthField(
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          password: true,
          onChanged: (_) {},
          validator: (value) =>
              value != null && value.isNotEmpty && value == password
              ? null
              : 'Passwords do not match',
        ),
        if (error != null) AuthError(message: error!),
        FilledButton(
          onPressed: busy ? null : _register,
          child: Text(busy ? 'Creating account...' : 'Create Account'),
        ),
        SocialAuthButtons(
          registration: true,
          state: widget.state,
          disabled: busy,
          onBusyChanged: (value) => setState(() => busy = value),
        ),
        TextButton(
          onPressed: () => widget.state.open('Login'),
          child: const Text('Already have an account? Login Now'),
        ),
      ],
    ),
  );
}
