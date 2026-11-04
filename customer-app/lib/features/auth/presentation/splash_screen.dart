import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/presentation/auth_controller.dart';

/// Splash / Boot screen — max 1.2s, then route based on session.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final booted = ref.read(authBootProvider).value ?? false;
    final signedIn = ref.read(authControllerProvider).value != null;
    if (booted) {
      context.go(signedIn ? '/home' : '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Scaffold(
      backgroundColor: colors.brand,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  'EG',
                  style: AppTypography.displayHero(colors.brand).copyWith(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'EASYGET Fresh Market',
              style: AppTypography.displayHero(Colors.white).copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '10-Minute Doorstep Delivery',
                style: AppTypography.label(Colors.white, size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
