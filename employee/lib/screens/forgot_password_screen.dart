import '../widgets/employee_icon.dart';

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/employee_ui.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final form = GlobalKey<FormState>();
  bool requested = false;
  bool busy = false;
  String email = '';
  String? error;

  Future<void> _reset() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
      requested = false;
    });
    try {
      await widget.state.auth.resetPassword(email);
      if (mounted) setState(() => requested = true);
    } catch (failure) {
      if (mounted) setState(() => error = authErrorMessage(failure));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, widget.state);
    return Form(
      key: form,
      child: ui.list([
        const EmployeeIcon(Icons.lock_reset, size: 80, color: Colors.blue),
        ui.heading('Reset Your Password'),
        ui.caption(
          'Enter your account email to receive a password reset link.',
        ),
        const SizedBox(height: 24),
        AuthField(
          label: 'Email Address',
          icon: Icons.mail_outline,
          keyboard: TextInputType.emailAddress,
          onChanged: (value) => email = value,
          validator: validateEmail,
        ),
        if (error != null) AuthError(message: error!),
        FilledButton(
          onPressed: busy ? null : _reset,
          child: Text(busy ? 'Sending...' : 'Request Reset Link'),
        ),
        if (requested)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ui.caption(
              'If an account exists for this email, a reset link will arrive shortly. Check your inbox and spam folder.',
            ),
          ),
        TextButton(
          onPressed: () => widget.state.open('Login'),
          child: const Text('Back to Login'),
        ),
      ]),
    );
  }
}
