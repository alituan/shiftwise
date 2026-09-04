/// Account bottom sheet — the design's single elevation case
/// (elevationSheet over content, docs/design/screens.md). Signed-out shows
/// guest info; signed-in shows the email plus verification status and
/// resend. State is live: signing out here switches to guest immediately.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/features/auth/auth_models.dart';
import 'package:shiftwise/features/auth/state/auth.dart';
import 'package:shiftwise/shared/widgets/status_chip.dart';

Future<void> showAccountSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      // Transparent so the sheet content carries the exact elevationSheet
      // token shadow (framework elevation is zeroed in the theme).
      backgroundColor: Colors.transparent,
      builder: (_) => const AccountSheet(),
    );

class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.designType;
    final colors = context.designColors;
    final authAsync = ref.watch(authUserProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Tokens.radiusMd),
        ),
        boxShadow: Tokens.elevationSheet,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account', style: type.title),
              const SizedBox(height: Tokens.spaceMd),
              authAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => Text(
                  'Sign-in state unavailable. Try again.',
                  style: type.body,
                ),
                data: (user) => user == null
                    ? const _GuestContent()
                    : _SignedInContent(user),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestContent extends ConsumerWidget {
  const _GuestContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.designType;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusChip(label: 'Guest', variant: StatusChipVariant.neutral),
        const SizedBox(height: Tokens.spaceXs),
        Text(
          'No account yet. Your shifts stay on this device in guest mode.',
          style: type.body,
        ),
        const SizedBox(height: Tokens.spaceLg),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/auth');
          },
          child: const Text('Sign in or create an account'),
        ),
      ],
    );
  }
}

class _SignedInContent extends ConsumerWidget {
  const _SignedInContent(this.user);

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.designType;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.email, style: type.body),
        const SizedBox(height: Tokens.spaceXs),
        StatusChip(
          label: user.isEmailVerified ? 'Email verified' : 'Email not verified',
          variant: user.isEmailVerified
              ? StatusChipVariant.confirmed
              : StatusChipVariant.concern,
        ),
        const SizedBox(height: Tokens.spaceLg),
        if (!user.isEmailVerified) ...[
          TextButton(
            onPressed: () => _resendVerification(context, ref),
            child: const Text('Resend verification email'),
          ),
          const SizedBox(height: Tokens.spaceXs),
        ],
        FilledButton(
          onPressed: () => ref.read(authControllerProvider).signOut(),
          child: const Text('Sign out'),
        ),
      ],
    );
  }

  Future<void> _resendVerification(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider).sendEmailVerification();
      messenger.showSnackBar(
        const SnackBar(content: Text('Verification email sent')),
      );
    } on AuthFailure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(authErrorMessage(failure.error))),
      );
    }
  }
}
