/// Demo Firebase options for emulator/guest development.
///
/// Placeholder values for the `demo-shiftwise` emulator project — no real
/// backend exists yet, and none of these values are secret. When the real
/// Firebase project is created (owner action), regenerate this file with
/// `flutterfire configure`; nothing else in the app needs to change.
library;

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions _demo = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: 'demo-app-id',
    messagingSenderId: 'demo-sender-id',
    projectId: 'demo-shiftwise',
    authDomain: 'demo-shiftwise.firebaseapp.com',
    storageBucket: 'demo-shiftwise.appspot.com',
  );

  /// Single demo config for every platform until `flutterfire configure`
  /// produces real per-platform options.
  static FirebaseOptions get currentPlatform => _demo;
}
