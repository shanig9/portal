import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../state/employee_controller.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/employee_ui.dart';

String indiaOtpPhone(String number) =>
    '+91' +
    number.replaceAll(RegExp(r'[\s-]'), '').replaceFirst(RegExp(r'^\+91'), '');

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({
    super.key,
    required this.state,
    this.registrationPhone,
    this.completeRegistration,
  });
  final EmployeeController state;
  final String? registrationPhone;
  final Future<AuthAccount> Function(AuthAccount)? completeRegistration;
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _form = GlobalKey<FormState>();
  String phone = '', code = '';
  String otpPhone = '';
  String? error;
  PhoneChallenge? challenge;
  bool busy = false, completed = false;
  int resendSeconds = 0;
  int request = 0;
  Timer? timer;
  Timer? requestTimeout;

  @override
  void initState() {
    super.initState();
    if (widget.registrationPhone != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    requestTimeout?.cancel();
    super.dispose();
  }

  Future<void> _complete(AuthAccount account) async {
    if (!mounted || completed) return;
    completed = true;
    requestTimeout?.cancel();
    final register = widget.completeRegistration;
    if (register != null) {
      setState(() => busy = true);
      try {
        final registered = await register(account);
        if (mounted) Navigator.of(context).pop(registered);
      } catch (failure) {
        if (!mounted) return;
        setState(() {
          completed = false;
          busy = false;
          challenge = null;
          code = '';
          error = authErrorMessage(failure);
        });
      }
      return;
    }
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
    final registrationPhone = widget.registrationPhone;
    if (!resend &&
        registrationPhone == null &&
        !(_form.currentState?.validate() ?? false))
      return;
    if (!resend) otpPhone = registrationPhone ?? indiaOtpPhone(phone);
    final currentRequest = ++request;
    setState(() {
      busy = true;
      error = null;
    });
    void failed(Object failure) {
      if (!mounted || currentRequest != request || completed) return;
      if (kDebugMode && failure is FirebaseAuthException) {
        debugPrint('Firebase OTP request failed: ' + failure.code);
      }
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
        otpPhone,
        resendToken: resend ? challenge?.resendToken : null,
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
      await _complete(await challenge!.confirm(code.trim()));
    } catch (failure) {
      if (mounted) setState(() => error = authErrorMessage(failure));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, widget.state);
    final registrationPhone = widget.registrationPhone;
    return PopScope<AuthAccount>(
      canPop: registrationPhone == null || !busy,
      child: Form(
        key: _form,
        child: ui.list([
          ui.heading(
            challenge == null && registrationPhone == null
                ? 'Sign in with phone'
                : 'Verify your phone',
          ),
          ui.caption(
            registrationPhone != null && challenge == null
                ? 'Verify your mobile number $registrationPhone to create your account.'
                : challenge == null
                ? 'Enter your 10-digit mobile number.'
                : 'Enter the 6-digit SMS code for $otpPhone.',
          ),
          const SizedBox(height: 20),
          if (challenge == null && registrationPhone == null) ...[
            AuthField(
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              prefixText: '+91 ',
              onChanged: (value) => phone = value,
              validator: (value) =>
                  RegExp(r'^\+91\d{10}$').hasMatch(indiaOtpPhone(value ?? ''))
                  ? null
                  : 'Enter a 10-digit mobile number.',
            ),
            const Text(
              'By continuing, you agree to receive a verification SMS. Message rates may apply. Google processes your number to prevent spam and abuse.',
            ),
            const SizedBox(height: 16),
          ] else if (challenge != null)
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
                  : registrationPhone == null
                  ? 'Verify and sign in'
                  : 'Verify and create account',
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
            if (registrationPhone == null)
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        request++;
                        challenge = null;
                        phone = '';
                        code = '';
                        error = null;
                        timer?.cancel();
                        requestTimeout?.cancel();
                      }),
                child: const Text('Use a different phone number'),
              ),
          ],
          if (registrationPhone == null)
            TextButton(
              onPressed: () => widget.state.open('Login'),
              child: const Text('Back to email login'),
            ),
        ]),
      ),
    );
  }
}
