import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../state/employee_controller.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/employee_ui.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _form = GlobalKey<FormState>();
  String phone = '', code = '';
  String? error;
  PhoneChallenge? challenge;
  bool busy = false, completed = false;
  int resendSeconds = 0;
  int request = 0;
  Timer? timer;
  Timer? requestTimeout;

  @override
  void dispose() {
    timer?.cancel();
    requestTimeout?.cancel();
    super.dispose();
  }

  void _complete(AuthAccount account) {
    if (!mounted || completed) return;
    completed = true;
    widget.state.authenticated(account);
  }

  void _startCooldown() {
    timer?.cancel();
    resendSeconds = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => resendSeconds--);
      if (resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _send({bool resend = false}) async {
    if (!resend && !(_form.currentState?.validate() ?? false)) return;
    final currentRequest = ++request;
    setState(() {
      busy = true;
      error = null;
    });
    void failed(Object failure) {
      if (!mounted || currentRequest != request || completed) return;
      requestTimeout?.cancel();
      setState(() {
        busy = false;
        error = authErrorMessage(failure);
      });
    }

    requestTimeout?.cancel();
    requestTimeout = Timer(const Duration(seconds: 90), () {
      if (!mounted || completed || currentRequest != request) return;
      request++;
      setState(() {
        busy = false;
        error = 'The request timed out. Please try again.';
      });
    });
    try {
      await widget.state.auth.sendPhoneCode(
        phone.replaceAll(RegExp(r'[\s-]'), ''),
        onCodeSent: (value) {
          if (!mounted || currentRequest != request || completed) return;
          requestTimeout?.cancel();
          setState(() {
            challenge = value;
            busy = false;
            _startCooldown();
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
    if (!(_form.currentState?.validate() ?? false) || challenge == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      _complete(await challenge!.confirm(code.trim()));
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
      key: _form,
      child: ui.list([
        ui.heading(
          challenge == null ? 'Sign in with phone' : 'Verify your phone',
        ),
        ui.caption(
          challenge == null
              ? 'Enter your phone number including the country code, for example +91.'
              : 'Enter the 6-digit code sent to $phone.',
        ),
        const SizedBox(height: 20),
        if (challenge == null) ...[
          AuthField(
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            onChanged: (value) => phone = value,
            validator: (value) =>
                RegExp(r'^\+[1-9]\d{7,14}$')
                    .hasMatch((value ?? '').replaceAll(RegExp(r'[\s-]'), ''))
                ? null
                : 'Include your country code, such as +91.',
          ),
          const Text(
            'By continuing, you agree to receive a verification SMS. Message rates may apply. Google processes your number to prevent spam and abuse.',
          ),
          const SizedBox(height: 16),
        ] else
          AuthField(
            label: 'Verification Code',
            icon: Icons.sms_outlined,
            keyboard: TextInputType.number,
            onChanged: (value) => code = value,
            validator: (value) =>
                RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter the 6-digit verification code',
          ),
        if (error != null) AuthError(message: error!),
        FilledButton(
          onPressed: busy
              ? null
              : challenge == null
              ? _send
              : _verify,
          child: Text(
            busy
                ? 'Please wait...'
                : challenge == null
                ? 'Send OTP'
                : 'Verify and sign in',
          ),
        ),
        if (challenge != null) ...[
          TextButton(
            onPressed: busy || resendSeconds > 0
                ? null
                : () => _send(resend: true),
            child: Text(
              resendSeconds > 0
                  ? 'Resend code in ${resendSeconds}s'
                  : 'Resend code',
            ),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    request++;
                    challenge = null;
                    code = '';
                    error = null;
                    timer?.cancel();
                    requestTimeout?.cancel();
                  }),
            child: const Text('Use a different phone number'),
          ),
        ],
        TextButton(
          onPressed: () => widget.state.open('Login'),
          child: const Text('Back to email login'),
        ),
      ]),
    );
  }
}
