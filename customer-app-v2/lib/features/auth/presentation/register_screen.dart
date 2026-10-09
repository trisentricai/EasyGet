import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import 'auth_controller.dart';

/// S3 · Register (DESIGN §12 S3): instant signup, per-field DRF errors,
/// auto-login. No OTP step — the `/verify` route is retired.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _coldStartHint = 'Waking up the store…';

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  bool _slow = false;
  Timer? _slowTimer;

  String _role = 'CUSTOMER';
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _phoneError;

  @override
  void dispose() {
    _slowTimer?.cancel();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
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

  Map<String, String> _fieldErrors(ApiException e) {
    final payload = e.payload;
    final out = <String, String>{};
    if (payload is Map) {
      payload.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          out['$key'] = value.first.toString();
        } else if (value is String && value.isNotEmpty) {
          out['$key'] = value;
        }
      });
    }
    return out;
  }

  Future<void> _submit() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _phoneError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _slow = false;
    });
    _startSlowTimer();

    final error = await ref.read(authControllerProvider.notifier).register(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          role: _role,
        );

    if (!mounted) return;
    _stopSlowTimer();
    setState(() => _busy = false);

    if (error == null) {
      context.go('/home');
      return;
    }

    final fields = _fieldErrors(error);
    final mapped = fields['first_name'] != null ||
        fields['email'] != null ||
        fields['password'] != null ||
        fields['phone'] != null;
    if (!mapped) {
      _showSnack(error.message);
      return;
    }
    setState(() {
      _nameError = fields['first_name'];
      _emailError = fields['email'];
      _passwordError = fields['password'];
      _phoneError = fields['phone'];
    });
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
                      'Create your account',
                      style:
                          AppTypography.displayHero(theme.colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fresh groceries, delivered fast.',
                      style: AppTypography.body(
                          theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        errorText: _nameError,
                      ),
                      onChanged: (_) {
                        if (_nameError != null) setState(() => _nameError = null);
                      },
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.mail_outline),
                        errorText: _emailError,
                      ),
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                      validator: (value) =>
                          (value == null || !value.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        errorText: _passwordError,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                      validator: (value) => (value == null || value.length < 8)
                          ? 'Minimum 8 characters'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Phone (optional)',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        errorText: _phoneError,
                      ),
                      onChanged: (_) {
                        if (_phoneError != null) {
                          setState(() => _phoneError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'CUSTOMER',
                          label: Text('Customer'),
                          icon: Icon(Icons.shopping_bag_outlined),
                        ),
                        ButtonSegment(
                          value: 'MERCHANT',
                          label: Text('Merchant'),
                          icon: Icon(Icons.storefront_outlined),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (selection) =>
                          setState(() => _role = selection.first),
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
                          : const Text('Create account'),
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
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.body(
                              theme.colorScheme.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: _busy ? null : () => context.pop(),
                          child: const Text('Sign in'),
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
