// test/auth_redirects_test.dart
//
// The emailed-link landing logic. This is subtle enough to be worth
// pinning: go_router uses hash routing, Supabase appends a query string,
// and the two only coexist if the redirect URL has no path in it.

import 'package:flutter_test/flutter_test.dart';
import 'package:triple_a/services/auth_redirects.dart';

void main() {
  group('AuthRedirects.detect', () {
    test('routes a signup confirmation to /email-confirmed', () {
      final uri = Uri.parse('https://shop.test/?flow=signup&code=ABC123');
      expect(AuthRedirects.detect(uri), '/email-confirmed');
    });

    test('routes a password reset to /reset-password', () {
      final uri = Uri.parse('https://shop.test/?flow=reset&code=XYZ789');
      expect(AuthRedirects.detect(uri), '/reset-password');
    });

    test('the appended code is reachable in queryParameters', () {
      // This is the whole point of the bare-origin redirect: with a hash
      // route the code would land in the fragment instead.
      final uri = Uri.parse('https://shop.test/?flow=reset&code=XYZ789');
      expect(uri.queryParameters['code'], 'XYZ789');
    });

    test('a hash-route redirect would LOSE the code (regression guard)', () {
      final bad = Uri.parse('https://shop.test/#/reset-password?code=XYZ789');
      expect(bad.queryParameters.containsKey('code'), isFalse,
          reason: 'proves why redirectTo must not contain "#/"');
    });

    test('returns null for an ordinary visit', () {
      expect(AuthRedirects.detect(Uri.parse('https://shop.test/')), isNull);
      expect(AuthRedirects.detect(Uri.parse('https://shop.test/#/cart')), isNull);
      expect(
        AuthRedirects.detect(Uri.parse('https://shop.test/#/check-email?email=a@b.c')),
        isNull,
      );
    });

    test('falls back to reset when a raw recovery token arrives', () {
      final uri = Uri.parse(
        'https://shop.test/#access_token=abc&refresh_token=def&type=recovery',
      );
      expect(AuthRedirects.detect(uri), '/reset-password');
    });

    // The case that actually happens locally: Supabase strips ?flow= because
    // the query string is not in the Redirect URLs allow-list, so the route
    // has to be decided from type= inside Supabase's fragment.
    test('signup fragment routes to /email-confirmed even without ?flow', () {
      final uri = Uri.parse(
        'https://shop.test/#access_token=abc&refresh_token=def&type=signup',
      );
      expect(AuthRedirects.detect(uri), '/email-confirmed');
    });

    test('a signup link is never mistaken for a password reset', () {
      final uri = Uri.parse('https://shop.test/#access_token=abc&type=signup');
      expect(AuthRedirects.detect(uri), isNot('/reset-password'));
    });

    test('honours an error fragment so the user gets an explanation', () {
      final uri = Uri.parse('https://shop.test/#error_description=otp_expired');
      expect(AuthRedirects.detect(uri), '/reset-password');
    });
  });

  group('AuthRedirects.hasFragmentTokens', () {
    test('true when Supabase tokens are in the fragment', () {
      expect(
        AuthRedirects.hasFragmentTokens(
          Uri.parse('https://shop.test/#access_token=abc&type=signup'),
        ),
        isTrue,
      );
    });

    test('false for a normal hash route', () {
      expect(
        AuthRedirects.hasFragmentTokens(Uri.parse('https://shop.test/#/cart')),
        isFalse,
      );
    });
  });

  group('AuthRedirects.isAuthCallback', () {
    test('true for a flow marker', () {
      expect(AuthRedirects.isAuthCallback(Uri.parse('https://a.test/?flow=reset')), isTrue);
    });

    test('true for tokens in the fragment', () {
      expect(
        AuthRedirects.isAuthCallback(Uri.parse('https://a.test/#access_token=x')),
        isTrue,
      );
    });

    test('false for a normal page', () {
      expect(AuthRedirects.isAuthCallback(Uri.parse('https://a.test/#/cart')), isFalse);
      expect(AuthRedirects.isAuthCallback(Uri.parse('https://a.test/')), isFalse);
    });
  });

  group('AuthRedirects targets', () {
    test('both flows share the origin and differ only by marker', () {
      expect(AuthRedirects.resetPassword, endsWith('/?flow=reset'));
      expect(AuthRedirects.confirmEmail, endsWith('/?flow=signup'));
      expect(AuthRedirects.resetPassword, isNot(contains('#')));
      expect(AuthRedirects.confirmEmail, isNot(contains('#')));
    });
  });
}