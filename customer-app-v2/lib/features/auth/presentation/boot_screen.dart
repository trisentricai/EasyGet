import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

/// S1 · Boot / Splash (DESIGN §12 S1): the router holds every redirect until
/// the session is resolved, so the app can never strand on a splash.
class BootScreen extends ConsumerStatefulWidget {
  const BootScreen({super.key});

  @override
  ConsumerState<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends ConsumerState<BootScreen> {
  static const _hint = 'Waking up the store…';

  Timer? _hintTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _scheduleHint();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Wake the sleeping free-tier backend while the splash shows, so login
      // after splash isn't delayed by the Render cold start.
      ref.read(apiClientProvider).warmUp();
      ref.read(authControllerProvider.notifier).boot();
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _scheduleHint() {
    _hintTimer?.cancel();
    _slow = false;
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  void _retry() {
    setState(() => _slow = false);
    _scheduleHint();
    ref.read(authControllerProvider.notifier).boot();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final failed = auth is AuthGuest && auth.coldStartHint;

    return Scaffold(
      backgroundColor: AppColors.brand,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.lightCanvas,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Text(
                    'EG',
                    style: AppTypography.displayHero(AppColors.brand),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'EASYGET',
                style: AppTypography.screenTitle(AppColors.lightCanvas)
                    .copyWith(letterSpacing: 6),
              ),
              if (_slow && auth is AuthBooting) ...[
                const SizedBox(height: 18),
                Text(
                  _hint,
                  style: AppTypography.caption(AppColors.lightCanvas),
                ),
              ],
              if (failed) ...[
                const SizedBox(height: 18),
                Text(
                  auth.error ?? 'Could not reach the store.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(AppColors.lightCanvas),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _retry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
