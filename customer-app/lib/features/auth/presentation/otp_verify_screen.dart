import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import 'auth_controller.dart';

/// OTP verification screen with 4-digit input boxes.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  bool _busy = false;
  int _resendCooldown = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_controllers.every((c) => c.text.length == 1)) {
      _verify();
    }
  }

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 4) return;
    setState(() => _busy = true);
    final error = await ref.read(authControllerProvider.notifier).verifyOtp(
          phone: widget.phone,
          code: code,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      _showSnack(error, error: true);
    } else {
      context.go('/home');
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() => _resendCooldown = 30);
    _startResendTimer();
    final error = await ref.read(authControllerProvider.notifier).sendOtp(widget.phone);
    if (error != null && mounted) _showSnack(error, error: true);
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shield illustration
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined, size: 48, color: colors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify 4-Digit Code',
                    style: AppTypography.displayHero(theme.colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We sent a code to ${widget.phone}',
                    style: AppTypography.body(theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // 4 digit inputs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: TextFormField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: AppTypography.tabularPrice(theme.colorScheme.onSurface, size: 24),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: theme.colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: colors.primary, width: 2),
                            ),
                          ),
                          onChanged: (v) => _onCodeChanged(i, v),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Resend timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Resend in ',
                        style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        '${_resendCooldown}s',
                        style: AppTypography.tabularNumber(colors.marigold, size: 14),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _resendCooldown > 0 ? null : _resend,
                    child: const Text('Resend Code'),
                  ),
                  const SizedBox(height: 24),
                  // Verify button
                  FilledButton(
                    onPressed: _busy ? null : _verify,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Verify & Enter Fresh Market'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
