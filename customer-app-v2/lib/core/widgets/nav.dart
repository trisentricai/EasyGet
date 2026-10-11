import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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