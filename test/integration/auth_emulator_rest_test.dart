/// Real Firebase Auth emulator flows at the Identity Toolkit REST protocol
/// level. Runs under a live emulator:
///
///     firebase emulators:exec --only auth -- "flutter test test/integration"
///
/// Skips itself when no emulator is reachable so plain `flutter test`
/// passes anywhere; CI starts the emulator and runs it for real.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _host = 'http://127.0.0.1:9099';
const _accounts = '$_host/identitytoolkit.googleapis.com/v1/accounts';

Future<bool> _emulatorUp() async {
  try {
    final socket = await Socket.connect('127.0.0.1', 9099, timeout: 500.ms);
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

Future<http.Response> _post(String action, Map<String, Object?> body) =>
    http.post(
      Uri.parse('$_accounts:$action?key=demo-api-key'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );

Map<String, Object?> _json(http.Response response) =>
    jsonDecode(response.body) as Map<String, Object?>;

extension on int {
  Duration get ms => Duration(milliseconds: this);
}

void main() {
  group('Firebase Auth emulator (REST protocol)', () {
    test('sign-up, duplicate, sign-in, wrong password, reset', () async {
      final up = await _emulatorUp();
      if (!up) {
        // ignore: avoid_print
        print('Auth emulator not reachable on 127.0.0.1:9099 — skipping.');
        return;
      }
      final email =
          'rest-${DateTime.now().millisecondsSinceEpoch}@shiftwise.test';
      const password = 'hunter22';

      final signUp = await _post('signUp', {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      expect(signUp.statusCode, 200, reason: signUp.body);
      final signUpBody = _json(signUp);
      expect(signUpBody['localId'], isNotEmpty);
      expect(
        signUpBody['emailVerified'] ?? false,
        isFalse,
        reason: 'new accounts must be unverified until the email link',
      );
      expect(signUpBody['idToken'], isNotEmpty);

      final duplicate = await _post('signUp', {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      expect(duplicate.statusCode, 400);
      expect(
        (_json(duplicate)['error'] as Map<String, Object?>)['message'],
        'EMAIL_EXISTS',
      );

      final signIn = await _post('signInWithPassword', {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      expect(signIn.statusCode, 200, reason: signIn.body);
      expect(_json(signIn)['email'], email);

      final wrongPassword = await _post('signInWithPassword', {
        'email': email,
        'password': 'wrongpass',
        'returnSecureToken': true,
      });
      expect(wrongPassword.statusCode, 400);
      expect(
        (_json(wrongPassword)['error'] as Map<String, Object?>)['message'],
        'INVALID_PASSWORD',
      );

      final reset = await _post('sendOobCode', {
        'requestType': 'PASSWORD_RESET',
        'email': email,
      });
      expect(reset.statusCode, 200, reason: reset.body);
      expect(_json(reset)['email'], email);
    });
  });
}
