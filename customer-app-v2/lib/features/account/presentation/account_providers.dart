import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/storefront_appearance.dart';
import '../../auth/data/app_user.dart';
import '../data/profile_repository.dart';

/// S12 · Profile state for the Account screen.
final profileProvider = FutureProvider<AppUser>(
  (ref) => ref.watch(profileRepositoryProvider).fetch(),
);

/// App theme mode (Light / Dark / System). Local-only for v1.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// MaterialApp's mode: the shopper's explicit Light/Dark choice wins; on
/// "Auto" (system) the admin-configured mobile default applies.
final effectiveThemeModeProvider = Provider<ThemeMode>((ref) {
  final local = ref.watch(themeModeProvider);
  if (local != ThemeMode.system) return local;
  return ref.watch(storefrontAppearanceProvider).themeMode;
});

/// Notification toggle (local stub — server preferences land later).
class NotificationsController extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final notificationsEnabledProvider =
    NotifierProvider<NotificationsController, bool>(
  NotificationsController.new,
);