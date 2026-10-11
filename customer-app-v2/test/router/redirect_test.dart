import 'package:easyget/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

const _private = [
  '/home',
  '/browse',
  '/search',
  '/cart',
  '/orders',
  '/checkout',
  '/account',
  '/addresses',
  '/wishlist',
  '/product/milk',
];

const _public = ['/login', '/register'];

void main() {
  group('not booted', () {
    for (final location in ['/', ..._public, ..._private]) {
      test('$location holds before boot resolves', () {
        expect(redirectFor(location, booted: false, signedIn: false), isNull);
        expect(redirectFor(location, booted: false, signedIn: true), isNull);
      });
    }
  });

  group('booted + signedIn', () {
    test('/ redirects to /home', () {
      expect(redirectFor('/', booted: true, signedIn: true), '/home');
    });

    for (final location in _public) {
      test('$location redirects to /home', () {
        expect(redirectFor(location, booted: true, signedIn: true), '/home');
      });
    }

    for (final location in _private) {
      test('$location is allowed', () {
        expect(redirectFor(location, booted: true, signedIn: true), isNull);
      });
    }
  });

  group('booted + guest', () {
    test('/ redirects to /login', () {
      expect(redirectFor('/', booted: true, signedIn: false), '/login');
    });

    for (final location in _public) {
      test('$location is allowed', () {
        expect(redirectFor(location, booted: true, signedIn: false), isNull);
      });
    }

    for (final location in _private) {
      test('$location redirects to /login', () {
        expect(redirectFor(location, booted: true, signedIn: false), '/login');
      });
    }
  });
}
