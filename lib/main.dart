/// Entry point. Firebase initializes with demo options so guest mode works
/// without any project; see shared/firebase/firebase_bootstrap.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftwise/app/app.dart';
import 'package:shiftwise/shared/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const ProviderScope(child: ShiftWiseApp()));
}
