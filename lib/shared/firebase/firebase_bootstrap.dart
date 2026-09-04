/// Firebase initialization for guest/emulator development.
///
/// Emulator: run `firebase emulators:start --only auth` (or `npm test:auth`)
/// and launch the app with `--dart-define=USE_FIREBASE_EMULATOR=true`.
/// Without the define, Firebase still initializes with demo options —
/// guest mode never calls Auth, so the app boots and works; only
/// sign-in/sign-up/reset need the emulator (or a real project) to succeed.
library;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shiftwise/firebase_options.dart';

const bool useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (useFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  }
  await _activateAppCheck();
}

/// App Check debug providers on native platforms, best-effort: the demo
/// project has no registered debug token, and web needs a real reCAPTCHA
/// key. Enforcement matters once Firestore lands (docs/threat-model.md).
Future<void> _activateAppCheck() async {
  if (kIsWeb) return;
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
  } catch (_) {
    // Best-effort only until the real project exists.
  }
}
