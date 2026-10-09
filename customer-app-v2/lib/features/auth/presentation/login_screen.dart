import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../data/google_auth_source.dart';
import 'auth_controller.dart';

/// S2 · Login (DESIGN §12 S2): email/password + Google, cold-start aware.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _coldStartHint = 'Waking up the store…';

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  bool _slow = false;
  Timer? _slowTimer;

  @override
  void dispose() {
    _slowTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startSlowTimer() {
    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _busy) setState(() => _slow = true);
    });
  }

  void _stopSlowTimer() {
    _slowTimer?.cancel();
    _slow = false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _slow = false;
    });
    _startSlowTimer();

    final error = await ref.read(authControllerProvider.notifier).signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    _stopSlowTimer();
    setState(() => _busy = false);

    if (error != null) {
      _showSnack(error);
      return;
    }
    context.go('/home');
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _busy = true;
      _slow = false;
    });
    _startSlowTimer();

    String? idToken;
    try {
      idToken = await ref.read(googleAuthSourceProvider).fetchIdToken();
    } on ApiException catch (e) {
      if (!mounted) return;
      _stopSlowTimer();
      setState(() => _busy = false);
      _showSnack(e.message);
      return;
    }

    if (!mounted) return;
    if (idToken == null) {
      // User cancelled: stay put.
      _stopSlowTimer();
      setState(() => _busy = false);
      return;
    }

    final error =
        await ref.read(authControllerProvider.notifier).signInWithGoogle(idToken);
    if (!mounted) return;
    _stopSlowTimer();
    setState(() => _busy = false);

    if (error != null) {
      _showSnack(error);
      return;
    }
    context.go('/home');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.brand, colors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Text(
                            'EG',
                            style: AppTypography.displayHero(Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome back',
                      style:
                          AppTypography.displayHero(theme.colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in for quick commerce near you.',
                      style: AppTypography.body(
                          theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) => (value == null || !value.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) => (value == null || value.length < 8)
                          ? 'Minimum 8 characters'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    if (_slow)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _coldStartHint,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption(
                              theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: AppTypography.caption(
                                theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _googleSignIn,
                      icon: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New here? ',
                          style: AppTypography.body(
                              theme.colorScheme.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed:
                              _busy ? null : () => context.push('/register'),
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
