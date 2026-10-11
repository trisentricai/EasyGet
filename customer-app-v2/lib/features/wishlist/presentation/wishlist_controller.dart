import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wishlist_repository.dart';

/// Hearts-only wishlist state (v1 — no dedicated screen). Slugs are cached
/// after the first fetch; toggles apply optimistically and roll back if the
/// server call fails.
class WishlistController extends Notifier<AsyncValue<Set<String>>> {
  @override
  AsyncValue<Set<String>> build() {
    _load();
    return const AsyncLoading();
  }

  Future<void> _load() async {
    try {
      final slugs =
          await ref.read(wishlistRepositoryProvider).fetch();
      state = AsyncData(slugs.toSet());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  bool hearted(String slug) => state.value?.contains(slug) ?? false;

  /// Flips the heart optimistically; rolls back and returns false when the
  /// server call fails so the failure is never silent.
  Future<bool> toggle(String slug) async {
    final currently = hearted(slug);
    final optimistic = {...(state.value ?? {})};
    if (currently) {
      optimistic.remove(slug);
    } else {
      optimistic.add(slug);
    }
    state = AsyncData(optimistic);
    try {
      await ref
          .read(wishlistRepositoryProvider)
          .toggle(slug, hearted: currently);
      return true;
    } catch (_) {
      final rollback = {...optimistic};
      if (currently) {
        rollback.add(slug);
      } else {
        rollback.remove(slug);
      }
      state = AsyncData(rollback);
      return false;
    }
  }

  Future<void> refresh() => _load();
}

final wishlistControllerProvider =
    NotifierProvider<WishlistController, AsyncValue<Set<String>>>(
  WishlistController.new,
);