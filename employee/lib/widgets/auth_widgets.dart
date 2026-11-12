import 'employee_icon.dart';

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../services/auth_service.dart';

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
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.zero,
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
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 190),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          'assets/images/auth_hero.png',
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: SizedBox()),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 24, 12, 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  registration
                                      ? 'Create Your\nAccount'
                                      : 'Find Your\nDream Job',
                                  style: const TextStyle(
                                    fontSize: 22,
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
                                    fontSize: 11,
                                    color: Color(0xFF53617B),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
          'Career Connect · Find your next opportunity.',
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
        prefixIcon: EmployeeIcon(widget.icon),
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
                icon: EmployeeIcon(
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

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Enter email address';
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? null
      : 'Enter a valid email address';
}

class AuthError extends StatelessWidget {
  const AuthError({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}

class SocialAuthButtons extends StatefulWidget {
  const SocialAuthButtons({
    super.key,
    required this.registration,
    required this.state,
    this.disabled = false,
    this.onBusyChanged,
  });
  final bool registration;
  final EmployeeController state;
  final bool disabled;
  final ValueChanged<bool>? onBusyChanged;
  @override
  State<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends State<SocialAuthButtons> {
  bool busy = false;
  String? error;

  Future<void> _google() async {
    widget.onBusyChanged?.call(true);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final account = await widget.state.auth.google();
      if (mounted) widget.state.authenticated(account);
    } catch (failure) {
      if (mounted) setState(() => error = authErrorMessage(failure));
    } finally {
      if (mounted) {
        setState(() => busy = false);
        widget.onBusyChanged?.call(false);
      }
    }
  }

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
                widget.registration ? 'Or register with' : 'Or continue with',
                style: const TextStyle(color: Colors.blueGrey),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      ),
      if (error != null) AuthError(message: error!),
      ...['Google'].map(
        (provider) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy || widget.disabled ? null : _google,
              icon: EmployeeIcon(
                provider == 'Google'
                    ? Icons.g_mobiledata
                    : Icons.business_center_outlined,
              ),
              label: Text(busy ? 'Signing in...' : 'Continue with $provider'),
            ),
          ),
        ),
      ),
    ],
  );
}
