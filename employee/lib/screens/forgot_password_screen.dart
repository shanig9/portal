import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/employee_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final form = GlobalKey<FormState>();
  bool requested = false;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, widget.state);
    return Form(
      key: form,
      child: ui.list([
        const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
        ui.heading('Reset Your Password'),
        ui.caption(
          'Enter the email or mobile number associated with your account.',
        ),
        const SizedBox(height: 24),
        AuthField(
          label: 'Email or Mobile Number',
          icon: Icons.mail_outline,
          onChanged: (_) {},
          validator: validateIdentity,
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) setState(() => requested = true);
          },
          child: const Text('Request Reset Link'),
        ),
        if (requested)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ui.caption(
              'Reset request preview complete. Delivery will be enabled when authentication is connected.',
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
