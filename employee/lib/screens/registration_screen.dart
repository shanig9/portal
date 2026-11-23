import 'package:material_ui/material_ui.dart';

import '../state/employee_controller.dart';
import '../widgets/auth_widgets.dart';
import '../services/auth_service.dart';
import 'phone_login_screen.dart';

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
      final auth = widget.state.auth;
      final registrationName = name;
      final registrationEmail = email;
      final registrationPassword = password;
      final registrationPhone = indiaOtpPhone(mobile);
      final account = await Navigator.of(context).push<AuthAccount>(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Verify mobile number')),
            body: PhoneLoginScreen(
              state: widget.state,
              registrationPhone: registrationPhone,
              completeRegistration: (verified) => auth.register(
                registrationName,
                registrationEmail,
                registrationPassword,
                verifiedPhoneUid: verified.uid,
              ),
            ),
          ),
        ),
      );
      if (!mounted || account == null) return;
      widget.state.authenticated(account, onboarding: true);
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
          prefixText: '+91 ',
          onChanged: (value) => mobile = value,
          validator: (value) =>
              RegExp(r'^\+91\d{10}$').hasMatch(indiaOtpPhone(value ?? ''))
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
        const Text('We’ll send an SMS code to verify your mobile number.'),
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
