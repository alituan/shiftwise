/// Sign-in / sign-up / password-reset screen.
///
/// Opening it while signed in bounces straight back — a UX convenience
/// only, never a security control (docs/architecture/sync-and-auth.md).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/features/auth/auth_models.dart';
import 'package:shiftwise/features/auth/state/auth.dart';

enum _AuthMode { signIn, signUp, reset }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _resetSent = false;
  bool _bouncedBack = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _isPasswordMode => _mode != _AuthMode.reset;

  String get _title => switch (_mode) {
    _AuthMode.signIn => 'Sign in',
    _AuthMode.signUp => 'Create account',
    _AuthMode.reset => 'Reset password',
  };

  String get _submitLabel => switch (_mode) {
    _AuthMode.signIn => 'Sign in',
    _AuthMode.signUp => 'Create account',
    _AuthMode.reset => 'Send reset email',
  };

  @override
  Widget build(BuildContext context) {
    final type = context.designType;
    final colors = context.designColors;
    final authAsync = ref.watch(authUserProvider);
    final signedIn =
        authAsync is AsyncData<AuthUser?> && authAsync.value != null;
    if (signedIn && !_bouncedBack) {
      _bouncedBack = true;
      // UX-only bounce: signed-in users have nothing to do here.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
    }
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Tokens.spaceMd),
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              style: type.body,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            if (_isPasswordMode) ...[
              const SizedBox(height: Tokens.spaceMd),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                style: type.body,
                validator: (value) => (value?.length ?? 0) < 6
                    ? 'Use at least 6 characters'
                    : null,
              ),
            ],
            if (_mode == _AuthMode.signUp) ...[
              const SizedBox(height: Tokens.spaceMd),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                style: type.body,
                validator: (value) =>
                    value != _password.text ? "Passwords don't match" : null,
              ),
            ],
            const SizedBox(height: Tokens.spaceLg),
            if (_error != null) ...[
              // Critical color as icon pairing with an ink label — never
              // small color-only body text (docs/design/tokens.md rule).
              Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: colors.critical,
                  ),
                  const SizedBox(width: Tokens.spaceXs),
                  Expanded(child: Text(_error!, style: type.body)),
                ],
              ),
              const SizedBox(height: Tokens.spaceMd),
            ],
            if (_resetSent) ...[
              Text('Check your email for a reset link.', style: type.body),
              const SizedBox(height: Tokens.spaceMd),
            ],
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_submitLabel),
            ),
            const SizedBox(height: Tokens.spaceMd),
            switch (_mode) {
              _AuthMode.signIn => TextButton(
                onPressed: _switchTo(_AuthMode.reset),
                child: const Text('Forgot your password?'),
              ),
              _ => TextButton(
                onPressed: _switchTo(_AuthMode.signIn),
                child: const Text('Back to sign in'),
              ),
            },
            if (_mode == _AuthMode.signIn)
              TextButton(
                onPressed: _switchTo(_AuthMode.signUp),
                child: const Text('Create an account'),
              ),
            const SizedBox(height: Tokens.spaceLg),
            Text(
              'Guest mode keeps working without an account.',
              style: type.label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback _switchTo(_AuthMode mode) => () {
    setState(() {
      _mode = mode;
      _error = null;
      _resetSent = false;
    });
  };

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final controller = ref.read(authControllerProvider);
    final email = _email.text.trim();
    try {
      switch (_mode) {
        case _AuthMode.signIn:
          await controller.signIn(email: email, password: _password.text);
          if (mounted) context.go('/');
        case _AuthMode.signUp:
          await controller.signUp(email: email, password: _password.text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created. Check your email to verify.'),
              ),
            );
            context.go('/');
          }
        case _AuthMode.reset:
          await controller.sendPasswordReset(email);
          if (mounted) setState(() => _resetSent = true);
      }
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = authErrorMessage(failure.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
