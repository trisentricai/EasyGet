import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/states.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cart/presentation/cart_controller.dart';
import '../data/account_repository.dart';

final _profileProvider = FutureProvider((ref) {
  return ref.watch(accountRepositoryProvider).profile();
});

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: profile.when(
        loading: () => const LoadingList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(_profileProvider),
        ),
        data: (user) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        (user.displayName.isNotEmpty
                                ? user.displayName[0]
                                : '?')
                            .toUpperCase(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (user.phone.isNotEmpty)
                            Text(
                              user.phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Delivery addresses'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/addresses'),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('My orders'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go('/orders'),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart_outlined),
                    title: const Text('My cart'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go('/cart'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.logout_rounded,
                    color: theme.colorScheme.error),
                title: Text('Sign out',
                    style: TextStyle(color: theme.colorScheme.error)),
                onTap: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .signOut();
                  ref.invalidate(cartControllerProvider);
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'EasyGet · v0.1.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
