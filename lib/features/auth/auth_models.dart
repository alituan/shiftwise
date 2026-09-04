/// Auth value types and friendly error copy — UI code never touches the
/// Firebase SDK types directly (the gateway seam keeps that isolated).
library;

enum AuthError {
  invalidEmail,
  wrongCredentials,
  emailInUse,
  weakPassword,
  tooManyRequests,
  networkError,
  unknown,
}

/// Client-facing copy. Wrong-email and wrong-password collapse into one
/// message so the UI never confirms which accounts exist (user-enumeration
/// hygiene, docs/threat-model.md).
String authErrorMessage(AuthError error) => switch (error) {
  AuthError.invalidEmail => "That email address doesn't look right.",
  AuthError.wrongCredentials => 'Incorrect email or password.',
  AuthError.emailInUse => 'An account already exists for this email.',
  AuthError.weakPassword => 'Use a stronger password (at least 6 characters).',
  AuthError.tooManyRequests => 'Too many attempts. Try again in a few minutes.',
  AuthError.networkError =>
    'Network problem. Check your connection and try again.',
  AuthError.unknown => 'Something went wrong. Try again.',
};

class AuthFailure implements Exception {
  const AuthFailure(this.error);

  final AuthError error;

  @override
  String toString() => 'AuthFailure($error)';
}

/// Immutable snapshot of the signed-in user; verification status is
/// surfaced but never gates sign-in (approved Phase 2 decision).
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.isEmailVerified,
  });

  final String uid;
  final String email;
  final bool isEmailVerified;
}
