import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'auth_service.dart';
import 'models.dart';
import 'profile_screens.dart' show companyFields;
import 'screens.dart' show PortalScreen, WelcomeScreen;
import 'widgets.dart';
import 'hr_icon.dart';

Company companyForAccount(HrAccount account) => Company()
  ..name = account.name ?? 'Your company'
  ..email = account.email ?? ''
  ..phone = account.phone ?? ''
  ..location = ''
  ..website = ''
  ..about = '';

void _finishAuth(BuildContext context, HrAccount account, [Company? company]) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) =>
          PortalScreen(company: company ?? companyForAccount(account)),
    ),
    (_) => false,
  );
}

Future<void> signOutEmployer(BuildContext context) async {
  try {
    await HrAuthScope.of(context).signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(hrAuthError(error))));
    }
  }
}

String? _emailValidator(String? value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
    ? null
    : 'Enter a valid email address';
String _otpPhone(String value) =>
    '+91' +
    value.replaceAll(RegExp(r'[\s-]'), '').replaceFirst(RegExp(r'^\+91'), '');

String? _phoneValidator(String? value) =>
    RegExp(r'^\+91\d{10}$').hasMatch(_otpPhone(value ?? ''))
    ? null
    : 'Enter a 10-digit mobile number.';

class AuthInput extends StatefulWidget {
  const AuthInput({
    super.key,
    required this.label,
    required this.onChanged,
    this.password = false,
    this.keyboard,
    this.validator,
    this.prefixText,
  });
  final String label;
  final ValueChanged<String> onChanged;
  final bool password;
  final TextInputType? keyboard;
  final FormFieldValidator<String>? validator;
  final String? prefixText;
  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  bool visible = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey(widget.label),
      keyboardType: widget.keyboard,
      obscureText: widget.password && !visible,
      autocorrect: !widget.password,
      enableSuggestions: !widget.password,
      onChanged: widget.onChanged,
      validator:
          widget.validator ??
          (value) => (value?.isEmpty ?? true) ? 'Enter ${widget.label}' : null,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: widget.prefixText,
        floatingLabelBehavior: widget.prefixText == null
            ? null
            : FloatingLabelBehavior.always,
        prefixIcon: HrIcon(hrFieldIcon(widget.label)),
        suffixIcon: widget.password
            ? IconButton(
                tooltip: visible
                    ? 'Hide ${widget.label}'
                    : 'Show ${widget.label}',
                onPressed: () => setState(() => visible = !visible),
                icon: Icon(
                  visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
      ),
    ),
  );
}

class _AuthError extends StatelessWidget {
  const _AuthError(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  bool emailMode = true, busy = false;
  String email = '', password = '', phone = '';
  String? error;
  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    if (!emailMode) {
      go(context, OtpScreen(phone: _otpPhone(phone)));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final account = await HrAuthScope.of(context).signIn(email, password);
      if (mounted) _finishAuth(context, account);
    } catch (failure) {
      if (mounted) setState(() => error = hrAuthError(failure));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          const Brand(),
          heading('Employer Login'),
          muted('Sign in to your company account and start hiring.'),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Email')),
              ButtonSegment(value: false, label: Text('Phone OTP')),
            ],
            selected: {emailMode},
            onSelectionChanged: busy
                ? null
                : (value) => setState(() {
                    emailMode = value.first;
                    error = null;
                  }),
          ),
          const SizedBox(height: 24),
          if (emailMode) ...[
            AuthInput(
              label: 'Email Address',
              keyboard: TextInputType.emailAddress,
              onChanged: (value) => email = value,
              validator: _emailValidator,
            ),
            AuthInput(
              label: 'Password',
              password: true,
              onChanged: (value) => password = value,
            ),
          ] else
            AuthInput(
              label: 'Phone Number',
              keyboard: TextInputType.phone,
              prefixText: '+91 ',
              onChanged: (value) => phone = value,
              validator: _phoneValidator,
            ),
          if (error != null) _AuthError(error!),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(
              busy
                  ? 'Signing in...'
                  : emailMode
                  ? 'Sign in'
                  : 'Send OTP',
            ),
          ),
          if (emailMode)
            TextButton(
              onPressed: busy
                  ? null
                  : () => go(context, const ResetPasswordScreen()),
              child: const Text('Forgot Password?'),
            ),
          const SizedBox(height: 24),
          card(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HrIconTile(Icons.person_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New to Career Connect?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      muted(
                        'Create an employer account and start hiring today.',
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => go(context, const RegistrationScreen()),
                        child: const Text('Register as Employer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final form = GlobalKey<FormState>();
  final company = Company()
    ..name = ''
    ..location = ''
    ..phone = ''
    ..email = '';
  bool emailMode = true, agreed = false;
  String password = '';
  String? error;
  void _submit() {
    if (!form.currentState!.validate()) return;
    if (!agreed) {
      setState(() => error = 'Please accept the terms to continue.');
      return;
    }
    final validation = _phoneValidator(company.phone);
    if (validation != null) {
      setState(() => error = validation);
      return;
    }
    final auth = HrAuthScope.of(context);
    final draft = company.copy();
    final registrationPassword = password;
    setState(() => error = null);
    go(
      context,
      OtpScreen(
        company: draft,
        phone: _otpPhone(draft.phone),
        completeRegistration: emailMode
            ? (verified) => auth.register(
                draft.name,
                draft.email,
                registrationPassword,
                verifiedPhoneUid: verified.uid,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          const Brand(),
          heading('Employer Registration'),
          muted('Create your company account and start hiring.'),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Email')),
              ButtonSegment(value: false, label: Text('Phone OTP')),
            ],
            selected: {emailMode},
            onSelectionChanged: (value) => setState(() {
              emailMode = value.first;
              error = null;
            }),
          ),
          const SizedBox(height: 24),
          ...companyFields(company, registration: true, phonePrefix: '+91 '),
          if (emailMode) ...[
            AuthInput(
              label: 'Password',
              password: true,
              onChanged: (value) => password = value,
              validator: (value) => (value?.length ?? 0) >= 8
                  ? null
                  : 'Use at least 8 characters',
            ),
            AuthInput(
              label: 'Confirm Password',
              password: true,
              onChanged: (_) {},
              validator: (value) =>
                  value != null && value.isNotEmpty && value == password
                  ? null
                  : 'Passwords do not match',
            ),
          ],
          muted('We’ll send an SMS code to verify your company phone number.'),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: agreed,
            onChanged: (value) => setState(() => agreed = value ?? false),
            title: const Text(
              'I agree to the Terms & Conditions and Privacy Policy',
            ),
          ),
          if (error != null) _AuthError(error!),
          FilledButton(
            onPressed: _submit,
            child: Text(
              emailMode ? 'Create Employer Account' : 'Register & Get OTP',
            ),
          ),
        ],
      ),
    ),
  );
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    this.company,
    required this.phone,
    this.completeRegistration,
  });
  final Company? company;
  final String phone;
  final Future<HrAccount> Function(HrAccount)? completeRegistration;
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final form = GlobalKey<FormState>();
  bool started = false, busy = true, completed = false;
  int seconds = 0, request = 0;
  String code = '';
  String? error;
  HrPhoneChallenge? challenge;
  Timer? cooldown, timeout;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send();
      });
    }
  }

  @override
  void dispose() {
    cooldown?.cancel();
    timeout?.cancel();
    super.dispose();
  }

  Future<void> _complete(HrAccount account) async {
    if (!mounted || completed) return;
    completed = true;
    timeout?.cancel();
    final register = widget.completeRegistration;
    if (register != null) {
      setState(() => busy = true);
      try {
        account = await register(account);
      } catch (failure) {
        if (!mounted) return;
        setState(() {
          completed = false;
          busy = false;
          challenge = null;
          code = '';
          error = hrAuthError(failure);
        });
        return;
      }
    }
    if (!mounted) return;
    widget.company?.phone = widget.phone;
    _finishAuth(context, account, widget.company);
  }

  Future<void> _send() async {
    final currentRequest = ++request;
    setState(() {
      busy = true;
      error = null;
    });
    void failed(Object failure) {
      if (!mounted || completed || currentRequest != request) return;
      if (kDebugMode && failure is FirebaseAuthException) {
        debugPrint('Firebase OTP request failed: ' + failure.code);
      }
      timeout?.cancel();
      setState(() {
        busy = false;
        error = hrAuthError(failure);
      });
    }

    timeout?.cancel();
    timeout = Timer(const Duration(seconds: 90), () {
      if (!mounted || completed || currentRequest != request) return;
      request++;
      setState(() {
        busy = false;
        error = 'The request timed out. Please try again.';
      });
    });
    try {
      await HrAuthScope.of(context).sendPhoneCode(
        widget.phone,
        resendToken: challenge?.resendToken,
        onCodeSent: (value) {
          if (!mounted || completed || currentRequest != request) return;
          timeout?.cancel();
          cooldown?.cancel();
          setState(() {
            busy = false;
            challenge = value;
            seconds = 60;
          });
          cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            setState(() => seconds--);
            if (seconds <= 0) timer.cancel();
          });
        },
        onVerified: (account) {
          if (currentRequest == request) _complete(account);
        },
        onError: failed,
      );
    } catch (failure) {
      failed(failure);
    }
  }

  Future<void> _verify() async {
    if (!form.currentState!.validate() || challenge == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await _complete(await challenge!.confirm(code.trim()));
    } catch (failure) {
      if (mounted) setState(() => error = hrAuthError(failure));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: widget.company == null || !busy,
    child: Scaffold(
      appBar: AppBar(),
      body: Form(
        key: form,
        child: PageBody(
          children: [
            const Brand(),
            heading('Verify Mobile Number'),
            muted('Continue with ${widget.phone}'),
            const SizedBox(height: 24),
            if (challenge != null)
              AuthInput(
                label: 'Verification code',
                keyboard: TextInputType.number,
                onChanged: (value) => code = value,
                validator: (value) =>
                    RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter a six-digit code',
              ),
            muted(
              'By continuing, you agree to receive a verification SMS. Message rates may apply. Google processes your number to prevent spam and abuse.',
            ),
            if (error != null) _AuthError(error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy || challenge == null ? null : _verify,
              child: Text(
                busy
                    ? 'Please wait...'
                    : widget.company == null
                    ? 'Verify and sign in'
                    : 'Verify and create account',
              ),
            ),
            TextButton(
              onPressed: busy || seconds > 0 ? null : _send,
              child: Text(
                seconds > 0 ? 'Resend code in ${seconds}s' : 'Send code again',
              ),
            ),
            TextButton(
              onPressed: widget.company != null && busy
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Use a different phone number'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final form = GlobalKey<FormState>();
  String email = '';
  String? error;
  bool busy = false, sent = false;
  Future<void> _reset() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      sent = false;
      error = null;
    });
    try {
      await HrAuthScope.of(context).resetPassword(email);
      if (mounted) setState(() => sent = true);
    } catch (failure) {
      if (mounted) setState(() => error = hrAuthError(failure));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          const Brand(),
          heading('Reset Password'),
          AuthInput(
            label: 'Email Address',
            keyboard: TextInputType.emailAddress,
            onChanged: (value) => email = value,
            validator: _emailValidator,
          ),
          if (error != null) _AuthError(error!),
          FilledButton(
            onPressed: busy ? null : _reset,
            child: Text(busy ? 'Sending...' : 'Send reset link'),
          ),
          if (sent)
            muted(
              'If an account exists for this email, a reset link will arrive shortly. Check your inbox and spam folder.',
            ),
        ],
      ),
    ),
  );
}
