/// The Scan screen, step 1 (client-side preprocessing only): pick or
/// photograph a schedule, crop to the user's own row, strip metadata by
/// re-encoding, then obtain explicit consent naming the AI processor
/// before anything is prepared for upload (docs/architecture/ai-import.md).
/// Manual entry is always reachable — no dead ends.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/features/scan/image_pipeline.dart';
import 'package:shiftwise/features/scan/scan_config.dart';
import 'package:shiftwise/features/scan/scan_state.dart';
import 'package:shiftwise/shared/widgets/status_chip.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(scanSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: switch (session.phase) {
        ScanPhase.idle => const _IdleView(),
        ScanPhase.capturing => const _BusyView(label: 'Opening the camera…'),
        ScanPhase.cropping => const _BusyView(label: 'Crop your schedule row'),
        ScanPhase.consent => _ConsentView(artifact: session.artifact!),
        ScanPhase.ready => _ReadyView(artifact: session.artifact!),
        ScanPhase.failed => _FailedView(rejection: session.rejection!),
      },
    );
  }
}

class _ManualEntryFallback extends StatelessWidget {
  const _ManualEntryFallback();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.push('/shift-edit'),
      child: const Text('Enter a shift manually instead'),
    );
  }
}

class _IdleView extends ConsumerWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.designType;
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(Tokens.spaceLg),
        shrinkWrap: true,
        children: [
          Text('Import your schedule', style: type.title),
          const SizedBox(height: Tokens.spaceXs),
          Text(
            'Photograph your work schedule and crop to your own row. '
            'Nothing is added to your schedule without your confirmation.',
            style: type.body,
          ),
          const SizedBox(height: Tokens.spaceLg),
          FilledButton.icon(
            onPressed: () => ref
                .read(scanSessionProvider.notifier)
                .pickAndPrepare(fromCamera: true, context: context),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Take a photo'),
          ),
          const SizedBox(height: Tokens.spaceXs),
          FilledButton.tonalIcon(
            onPressed: () => ref
                .read(scanSessionProvider.notifier)
                .pickAndPrepare(fromCamera: false, context: context),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose a photo'),
          ),
          const SizedBox(height: Tokens.spaceMd),
          const _ManualEntryFallback(),
        ],
      ),
    );
  }
}

class _BusyView extends StatelessWidget {
  const _BusyView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final type = context.designType;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: Tokens.spaceMd),
          Text(label, style: type.body),
        ],
      ),
    );
  }
}

class _ConsentView extends ConsumerWidget {
  const _ConsentView({required this.artifact});

  final ScanArtifact artifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.designType;
    final colors = context.designColors;
    return ListView(
      padding: const EdgeInsets.all(Tokens.spaceMd),
      children: [
        Text('Check your photo', style: type.title),
        const SizedBox(height: Tokens.spaceXs),
        Text(
          'This exact image — cropped on your device and with its metadata '
          'removed — is the only thing that would be uploaded.',
          style: type.body,
        ),
        const SizedBox(height: Tokens.spaceMd),
        ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          child: Image.memory(
            artifact.cleanJpegBytes,
            // Never scale a preview beyond the artifact's real size.
            cacheWidth: artifact.width,
          ),
        ),
        const SizedBox(height: Tokens.spaceMd),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceDim,
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Tokens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusChip(
                  label: 'Consent needed',
                  variant: StatusChipVariant.concern,
                ),
                const SizedBox(height: Tokens.spaceXs),
                Text(
                  'When you continue, your photo goes to $aiProcessorName '
                  'to draft shifts for your review. You confirm every shift '
                  'before it is saved. The photo is deleted after you '
                  'confirm, or within 24 hours.',
                  style: type.body,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Tokens.spaceLg),
        FilledButton(
          onPressed: () => ref.read(scanSessionProvider.notifier).consent(),
          child: const Text('Continue'),
        ),
        const SizedBox(height: Tokens.spaceXs),
        TextButton(
          onPressed: () => ref.read(scanSessionProvider.notifier).discard(),
          child: const Text('Discard the photo'),
        ),
        const SizedBox(height: Tokens.spaceMd),
        const _ManualEntryFallback(),
      ],
    );
  }
}

class _ReadyView extends ConsumerWidget {
  const _ReadyView({required this.artifact});

  final ScanArtifact artifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.designType;
    return ListView(
      padding: const EdgeInsets.all(Tokens.spaceMd),
      children: [
        const StatusChip(
          label: 'Prepared',
          variant: StatusChipVariant.confirmed,
        ),
        const SizedBox(height: Tokens.spaceXs),
        Text('Ready to import', style: type.title),
        const SizedBox(height: Tokens.spaceXs),
        Text(
          'Your photo is prepared and waiting. Uploading for AI review '
          'arrives with the next update — nothing has been sent anywhere.',
          style: type.body,
        ),
        const SizedBox(height: Tokens.spaceMd),
        ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          child: Image.memory(
            artifact.cleanJpegBytes,
            cacheWidth: artifact.width,
          ),
        ),
        const SizedBox(height: Tokens.spaceLg),
        TextButton(
          onPressed: () => ref.read(scanSessionProvider.notifier).discard(),
          child: const Text('Discard the photo'),
        ),
        const _ManualEntryFallback(),
      ],
    );
  }
}

class _FailedView extends ConsumerWidget {
  const _FailedView({required this.rejection});

  final ScanRejection rejection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.designType;
    final colors = context.designColors;
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(Tokens.spaceLg),
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: colors.critical,
              ),
              const SizedBox(width: Tokens.spaceXs),
              Expanded(
                child: Text(scanRejectionMessage(rejection), style: type.body),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),
          FilledButton(
            onPressed: () => ref.read(scanSessionProvider.notifier).restart(),
            child: const Text('Try another photo'),
          ),
          const SizedBox(height: Tokens.spaceMd),
          const _ManualEntryFallback(),
        ],
      ),
    );
  }
}
