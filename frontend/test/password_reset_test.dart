// test/password_reset_test.dart
//
// Covers the pure validation rules for the reset flow. These are the
// checks that would otherwise only surface after a user typed a bad
// password and hit submit.

import 'package:flutter_test/flutter_test.dart';
import 'package:triple_a/services/password_reset_service.dart';

void main() {
  group('validateNewPassword', () {
    test('rejects empty', () {
      expect(validateNewPassword(''), 'Password is required');
    });

    test('rejects shorter than the minimum', () {
      expect(validateNewPassword('12345'), passwordRules[0]);
    });

    test('minimum length matches the documented rule', () {
      expect(kMinPasswordLength, 6);
    });

    test('accepts exactly the minimum length', () {
      expect(validateNewPassword('123456'), isNull);
    });

    test('accepts a stronger password', () {
      expect(validateNewPassword('Passw0rd'), isNull);
    });
  });

  group('validateConfirmation', () {
    test('rejects empty confirmation', () {
      expect(validateConfirmation('Passw0rd', ''),
          'Please confirm your new password');
    });

    test('rejects a mismatch', () {
      expect(validateConfirmation('Passw0rd', 'Passw0rD'), 'Passwords do not match');
    });

    test('accepts an exact match', () {
      expect(validateConfirmation('Passw0rd', 'Passw0rd'), isNull);
    });
  });

  group('reset redirect', () {
    test('points at the bare origin, never a hash route', () {
      // A hash route would bury Supabase's appended ?code= in the fragment.
      final url = PasswordResetService.redirectTo;
      expect(url, isNot(contains('#/')));
      expect(url, contains('/?flow=reset'));
    });

    test('never throws regardless of the hosting scheme', () {
      expect(() => PasswordResetService.redirectTo, returnsNormally);
    });
  });
}