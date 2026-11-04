# Phase 4 — Wishlist screen + Engagement (notifications inbox, order-status
local alerts, app-update prompt)

Execute inline on `fix/flutter-web-and-ordering`. Per-task gate
(workdir `customer-app-v2/`): RED test observed failing → GREEN →
`flutter analyze` clean → full `flutter test` green → one conventional
commit → ledger line in
`.superpowers/sdd/2026-10-11-customer-app-v2-phase4-plan/progress.md`
(now created alongside). Stage only `customer-app-v2/**` (+ ledger).
Never `git add .`. New plugins land once, together, before E2/E3.

## W1 · Wishlist screen (`/wishlist`, pushed from Account)
1. RED `test/wishlist/wishlist_screen_test.dart`: grid renders full product
   rows; card heart removes + Undo snackbar restores; empty → EmptyState +
   Browse CTA; error → retry; Account row navigates (covered in account
   test update). → FAIL.
2. GREEN: `WishlistRepository.fetchProducts()` (full rows → CatalogProduct;
   update the 3 test fakes); `lib/features/wishlist/presentation/
   wishlist_screen.dart` (own AppBar + back, 2-col grid via
   `ProductCard.gridAspect`, hearts, Undo, skeleton/empty/error,
   pull-refresh); Account Wishlist row → `push('/wishlist')`; router
   `/wishlist` added to `_privateRoutes` (+ redirect_test if it enumerates).
   → PASS + analyze.
3. Commit: `feat(app): wishlist screen — saved grid, remove + undo`

Test command: `flutter test test/wishlist/`

## E1 · Notifications inbox (`/notifications`, bell + unread badge)
1. RED `test/notifications/notifications_screen_test.dart`: rows (icon by
   type, title/body, unread dot); tap → markRead + dot clears; Mark-all-read
   action; empty ("You're all caught up"); error → retry; shell home shows
   the bell badge from `unreadCountProvider` (hidden at 0). → FAIL.
2. GREEN: `lib/features/engagement/presentation/notifications_screen.dart`
   (+ `notifications_providers.dart`: list/count providers); bell action in
   Home AppBar with badge; Account keeps its toggle (unchanged).
   → PASS + analyze.
3. Commit: `feat(app): notifications inbox + unread badge`

Test command: `flutter test test/notifications/`

## E2 · Order-status local alerts (flutter_local_notifications)
1. `flutter pub add flutter_local_notifications` once (with E3 deps below);
   Android `POST_NOTIFICATIONS` permission entry; channel `order_updates`.
2. RED `test/engagement/order_watcher_test.dart`: new PENDING order →
   notify; status change → notify with new status; unchanged snapshot →
   silent; permission denied → silent, no crash. → FAIL.
3. GREEN: `LocalNotifier` interface + plugin impl;
   `OrderStatusWatcher` (60s Timer, app-open scope, previous-status map,
   permission-aware, stops when no active orders); started from EasyGetApp
   post-frame. → PASS + analyze.
4. Commit: `feat(app): local alerts on order status changes`

Test command: `flutter test test/engagement/`

## E3 · App-update prompt (package_info_plus + url_launcher)
1. Deps land with E2 (single `pub add` run).
2. RED `test/engagement/update_gate_test.dart`: update available →
   dialog (version + notes + Later/Update); mandatory → no Later;
   dismissed → not reshown this launch; check failure → silent. → FAIL.
3. GREEN: `UpdateGate` (checks once per launch post-frame, session
   dismissal flag, Update opens `downloadUrl`); hooked above the router in
   `main.dart`. → PASS + analyze.
4. Commit: `feat(app): app-update prompt gate`

Test command: `flutter test test/engagement/`

## Completion contract (per task)
- Every named test ran and was read; final run is the brief's
  `flutter test <dir>` → green; full suite green; analyze clean; commit per
  brief; deviation → `Ruling:` line in the Phase-4 ledger.
- FCM proper (google-services.json, server sender) is explicitly OUT —
  needs user Firebase project + backend sender config; proposed as Phase 5.
