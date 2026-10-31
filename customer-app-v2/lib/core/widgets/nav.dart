import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation law (binding — see `test/router/nav_test.dart` static guard):
/// tab roots (`/home /browse /search /cart /orders`) ALWAYS go(), never
/// push(). Pushing a StatefulShellRoute branch corrupts the page stack and
/// trips the framework duplicate-page-key assertion (`navigator.dart:4032`).
/// Detail screens ALWAYS push() so the system back button walks the stack.
///
/// Safe back for pushed detail screens: pops when a route is beneath,
/// otherwise falls back to the Home tab (deep links, fresh starts).
/// Detail screens MUST be opened with [context.push] (never [context.go])
/// so the Android system back button walks the stack instead of exiting.
void popOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
}