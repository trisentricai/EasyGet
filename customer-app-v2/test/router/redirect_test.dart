import 'package:easyget/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

const _guestBrowsable = [
  '/home',
  '/browse',
  '/browse/all',
  '/search',
  '/cart',
  '/product/milk',
];

const _private = [
  '/orders',
  '/checkout',
  '/account',
  '/addresses',
  '/wishlist',
  '/notifications',
  '/order/1',
];

const _public = ['/login', '/register'];

void main() {
  group('not booted', () {
    for (final location in ['/', ..._public, ..._guestBrowsable, ..._private]) {
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

    for (final location in [..._guestBrowsable, ..._private]) {
      test('$location is allowed', () {
        expect(redirectFor(location, booted: true, signedIn: true), isNull);
      });
    }
  });

  group('booted + guest', () {
    test('/ redirects to /home', () {
      expect(redirectFor('/', booted: true, signedIn: false), '/home');
    });

    for (final location in [..._public, ..._guestBrowsable]) {
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
