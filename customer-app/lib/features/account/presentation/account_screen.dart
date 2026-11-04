import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared_widgets/custom_app_bar.dart';
import '../../../features/account/data/account_repository.dart';
import '../../../models/user.dart';
import '../../auth/presentation/auth_controller.dart';

/// Account & Preferences screen.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: colors.danger),
                const SizedBox(height: 16),
                Text('Failed to load profile', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text(e.toString(), style: AppTypography.caption(theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (user) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              flexibleSpace: CustomAppBar(
                title: 'Account',
                showSearch: false,
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Profile header
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.brand,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                            style: AppTypography.displayHero(Colors.white).copyWith(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.displayName, style: AppTypography.displayHero(Colors.white).copyWith(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(user.phone, style: AppTypography.tabularNumber(Colors.white.withValues(alpha: 0.8), size: 14)),
                              const SizedBox(height: 2),
                              Text(user.email, style: AppTypography.caption(Colors.white.withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primaryTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: colors.primary),
                          const SizedBox(width: 8),
                          Text('Fresh Market Premium Member', style: AppTypography.label(colors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Referral
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invite friends, both get ₹100 grocery credit', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text('ANANYA100', style: AppTypography.tabularPrice(colors.primary, size: 16)),
                              ),
                              OutlinedButton(
                                onPressed: () {}, // Copy
                                child: const Text('Copy'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Account actions
                  _AccountAction(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery Pin & GPS Map',
                    subtitle: 'Manage your delivery locations',
                    onTap: () => context.push('/addresses'),
                  ),
                  _AccountAction(
                    icon: Icons.local_shipping_outlined,
                    title: 'Saved Addresses',
                    subtitle: 'Home, Work, and other locations',
                    onTap: () => context.push('/addresses'),
                  ),
                  _AccountAction(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications & Alerts',
                    subtitle: 'Order updates, promos, and more',
                    onTap: () {}, // TODO: notifications screen
                  ),
                  _AccountAction(
                    icon: Icons.local_offer_outlined,
                    title: 'Coupons & Wallet',
                    subtitle: 'Your active vouchers and credits',
                    onTap: () {}, // TODO: coupons screen
                  ),
                  const SizedBox(height: 16),
                  // Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Settings', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  ),
                  const SizedBox(height: 8),
                  _AccountAction(
                    icon: Icons.palette_outlined,
                    title: 'Theme Appearance',
                    subtitle: 'Light, Dark, or System',
                    onTap: () => _showThemeSheet(),
                  ),
                  _AccountAction(
                    icon: Icons.vibration_outlined,
                    title: 'Doorstep Arrival Haptics',
                    subtitle: 'Vibrate when rider arrives',
                    onTap: () {},
                    trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: colors.primary),
                  ),
                  _AccountAction(
                    icon: Icons.help_outline,
                    title: '24x7 Customer Help & FAQ',
                    subtitle: 'Chat, call, or browse help articles',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  // Sign out
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton(
                      onPressed: () => _signOut(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.danger,
                        side: BorderSide(color: colors.danger),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Sign Out', style: AppTypography.label(colors.danger)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
            Text('Theme Appearance', style: AppTypography.screenTitle(Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: 'System',
              onChanged: (_) {},
              child: Column(
                children: [
                  ...['Light Warm Paper', 'Dark Warm Charcoal', 'System'].map((t) => RadioListTile<String>(
                    title: Text(t, style: AppTypography.bodyMedium(Theme.of(context).colorScheme.onSurface)),
                    value: t,
                    activeColor: Theme.of(context).freshColors.primary,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sign Out', style: AppTypography.bodyMedium(Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to sign out?', style: AppTypography.body(Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).signOut();
              if (!mounted) return;
              context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Profile provider.
final profileProvider = FutureProvider<AppUser>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getProfile();
});