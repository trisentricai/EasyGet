import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../wishlist/presentation/wishlist_controller.dart';
import '../data/profile_repository.dart';
import 'account_providers.dart';

/// S12 · Account (`/account`, auth): profile header (monogram, name, phone,
/// inline edit) → rows (Addresses navigates; Wishlist shows its count; stub
/// rows announce "coming soon" honestly) → Settings (theme segmented +
/// local notifications toggle) → Help → Sign out (danger + confirm).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: const EasyGetAppBar(title: 'Account'),
      body: profile.when(
        loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(AppSpace.lg),
            child: Column(
              children: [
                SkeletonLine(height: 72, radius: 36),
                SizedBox(height: AppSpace.lg),
                SkeletonLine(),
                SizedBox(height: AppSpace.sm),
                SkeletonLine(width: 200),
              ],
            ),
          ),
        ),
        error: (_, _) => ErrorState(
          body: 'We could not load your profile.',
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (user) => _Content(user: user),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final wishlistCount =
        ref.watch(wishlistControllerProvider).value?.length ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primary,
                  child: Text(
                    _monogram(user.displayName),
                    style: AppTypography.screenTitle(
                        scheme.onPrimary),
                  ),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName,
                          style: AppTypography.screenTitle(
                              scheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(
                        user.phone.isEmpty
                            ? user.email
                            : user.phone,
                        style: AppTypography.body(
                            scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('profile-edit'),
                  onPressed: () =>
                      _EditProfileSheet.show(context, user),
                  icon: const Icon(Icons.edit_outlined),
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _NavRow(
            key: const Key('row-addresses'),
            icon: Icons.location_on_outlined,
            label: 'Addresses',
            onTap: () => context.go('/addresses'),
          ),
          _NavRow(
            icon: Icons.favorite_border,
            label: 'Wishlist',
            badge: '$wishlistCount',
            onTap: () =>
                showAppSnackbar(context, 'Wishlist is coming soon.'),
          ),
          _NavRow(
            icon: Icons.rate_review_outlined,
            label: 'My reviews',
            onTap: () => showAppSnackbar(
                context, 'Reviews are coming soon.'),
          ),
          _NavRow(
            icon: Icons.local_offer_outlined,
            label: 'Coupons',
            onTap: () =>
                showAppSnackbar(context, 'Coupons are coming soon.'),
          ),
          _NavRow(
            icon: Icons.payments_outlined,
            label: 'Payments',
            onTap: () => showAppSnackbar(
                context, 'Saved payments are coming soon.'),
          ),
          _SectionLabel(label: 'Settings'),
          _ThemeRow(),
          _NotificationsRow(),
          _NavRow(
            icon: Icons.help_outline,
            label: 'Help',
            onTap: () => _HelpSheet.show(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
            child: TextButton(
              key: const Key('sign-out'),
              onPressed: () => _SignOutSheet.show(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Sign out'),
            ),
          ),
          SizedBox(
              height:
                  AppSpace.xxl + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

String _monogram(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return 'E';
  final initials = parts.map((p) => p[0]).take(2).join();
  return initials.toUpperCase();
}

class _NavRow extends StatelessWidget {
  const _NavRow(
      {super.key,
      required this.icon,
      required this.label,
      this.badge,
      required this.onTap});

  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.md),
        child: Row(
          children: [
            Icon(icon, size: 22, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Text(label,
                  style: AppTypography.bodyMedium(
                      scheme.onSurface)),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).freshColors.sunken,
                  borderRadius:
                      BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(badge!,
                    style: AppTypography.tabularSmall(
                        scheme.onSurfaceVariant)),
              ),
              const SizedBox(width: AppSpace.sm),
            ],
            Icon(Icons.chevron_right,
                size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.sm),
      child: Text(label,
          style: AppTypography.productName(scheme.onSurface, size: 17)
              .copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _ThemeRow extends ConsumerWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.xs),
      child: Row(
        children: [
          Icon(Icons.brightness_6_outlined,
              size: 22, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text('Appearance',
                style: AppTypography.bodyMedium(
                    scheme.onSurface)),
          ),
          SegmentedButton<ThemeMode>(
            key: const Key('theme-segmented'),
            segments: const [
              ButtonSegment(
                  value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(
                  value: ThemeMode.system, label: Text('Auto')),
              ButtonSegment(
                  value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {mode},
            onSelectionChanged: (selected) => ref
                .read(themeModeProvider.notifier)
                .set(selected.single),
          ),
        ],
      ),
    );
  }
}

class _NotificationsRow extends ConsumerWidget {
  const _NotificationsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = ref.watch(notificationsEnabledProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Row(
        children: [
          Icon(Icons.notifications_outlined,
              size: 22, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text('Notifications',
                style: AppTypography.bodyMedium(
                    scheme.onSurface)),
          ),
          Switch(
            key: const Key('notif-switch'),
            value: enabled,
            onChanged: (value) => ref
                .read(notificationsEnabledProvider.notifier)
                .set(value),
          ),
        ],
      ),
    );
  }
}

class _HelpSheet {
  static Future<void> show(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need help?',
                  style:
                      AppTypography.screenTitle(scheme.onSurface)),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Write to support@easyget.app — we reply within a day.',
                style: AppTypography.body(
                    scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutSheet {
  static Future<void> show(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sign out?',
                  style:
                      AppTypography.screenTitle(scheme.onSurface)),
              const SizedBox(height: AppSpace.xs),
              Text('You can sign back in anytime.',
                  style: AppTypography.body(
                      scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('sign-out-confirm'),
                  onPressed: () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .signOut();
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: const Text('Sign out'),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(),
                child: const Text('Stay signed in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline profile editor (first/last/phone). Pops on success.
class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.user});

  final AppUser user;

  static Future<void> show(BuildContext context, AppUser user) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  @override
  ConsumerState<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _first =
      TextEditingController(text: widget.user.firstName);
  late final TextEditingController _last =
      TextEditingController(text: widget.user.lastName);
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phone);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_phone.text.trim().isNotEmpty &&
        !RegExp(r'^\d{10}$').hasMatch(_phone.text.trim())) {
      setState(() => _error = 'Enter a 10-digit phone number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).update(
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            phone: _phone.text.trim(),
          );
      ref.invalidate(profileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackbar(context, 'Profile updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ApiException
            ? e.message
            : 'Could not update your profile.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.lg + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.faint,
                    borderRadius:
                        BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text('Edit profile',
                  style:
                      AppTypography.screenTitle(scheme.onSurface)),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: _field(_first, 'First name',
                        key: const Key('profile-first')),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: _field(_last, 'Last name',
                        key: const Key('profile-last')),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              _field(_phone, 'Phone (10 digits)',
                  key: const Key('profile-phone'),
                  keyboard: TextInputType.phone),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(_error!,
                    key: const Key('profile-error'),
                    style:
                        AppTypography.caption(scheme.error)),
              ],
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                height: 54,
                child: FilledButton(
                  key: const Key('profile-save'),
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {Key? key, TextInputType? keyboard}) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return SizedBox(
      height: 52,
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.words,
        style: AppTypography.body(scheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
            borderSide: BorderSide(color: colors.faint),
          ),
        ),
      ),
    );
  }
}