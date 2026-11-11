import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../theme.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.state,
    required this.registration,
    required this.children,
  });
  final EmployeeController state;
  final bool registration;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0F4FF), Color(0xFFF6FAFF)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Icon(Icons.work_outline_rounded, size: 36, color: blue),
              ),
              const SizedBox(height: 20),
              Text(
                registration ? 'Create Your\nAccount' : 'Find Your\nDream Job',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10254A),
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                registration
                    ? 'Register now to start exploring job opportunities and build your career.'
                    : 'Discover opportunities, apply easily, and build your career.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF53617B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Login')),
            ButtonSegment(value: true, label: Text('Register')),
          ],
          selected: {registration},
          onSelectionChanged: (selection) {
            if (selection.first != registration) {
              state.open(selection.first ? 'Registration' : 'Login');
            }
          },
        ),
        const SizedBox(height: 24),
        ...children,
        const SizedBox(height: 20),
        const Text(
          'Frontend preview · account services will be connected later.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey, fontSize: 12),
        ),
      ],
    ),
  );
}

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.password = false,
    this.keyboard,
    this.validator,
  });
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final bool password;
  final TextInputType? keyboard;
  final FormFieldValidator<String>? validator;
  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool visible = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(widget.label),
      keyboardType: widget.keyboard,
      obscureText: widget.password && !visible,
      autocorrect: !widget.password,
      enableSuggestions: !widget.password,
      onChanged: widget.onChanged,
      validator:
          widget.validator ??
          (value) =>
              (value?.trim().isEmpty ?? true) ? 'Enter ${widget.label}' : null,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCDDEF2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCDDEF2)),
        ),
        suffixIcon: widget.password
            ? IconButton(
                tooltip: visible
                    ? 'Hide ${widget.label}'
                    : 'Show ${widget.label}',
                onPressed: () => setState(() => visible = !visible),
                icon: Icon(
                  visible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    ),
  );
}

String? validateIdentity(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter email or mobile number';
  final email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text);
  final phone =
      RegExp(r'^\+?[\d\s-]{10,16}$').hasMatch(text) &&
      text.replaceAll(RegExp(r'\D'), '').length >= 10;
  return email || phone ? null : 'Enter a valid email or mobile number';
}

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({super.key, required this.registration});
  final bool registration;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                registration ? 'Or register with' : 'Or continue with',
                style: const TextStyle(color: Colors.blueGrey),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      ),
      ...['Google', 'LinkedIn'].map(
        (provider) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Continue with $provider'),
                  content: const Text(
                    'This sign-in option will be available when authentication is connected.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              icon: Icon(
                provider == 'Google'
                    ? Icons.g_mobiledata
                    : Icons.business_center_outlined,
              ),
              label: Text('Continue with $provider'),
            ),
          ),
        ),
      ),
    ],
  );
}
