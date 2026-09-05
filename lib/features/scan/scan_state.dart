/// The scan screen's client-side state machine
/// (docs/design/screens.md Scan, docs/architecture/ai-import.md).
///
/// idle → capturing → cropping → consent → ready, with failed for rejected
/// images and cancellation returning to idle from anywhere. The backend
/// job states (uploaded/queued/processing/review_required/confirmed/
/// expired) arrive with later Phase 3 steps; nothing here uploads.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'image_pipeline.dart';
import 'image_source_gateway.dart';

enum ScanPhase { idle, capturing, cropping, consent, ready, failed }

@immutable
class ScanSessionState {
  const ScanSessionState({required this.phase, this.artifact, this.rejection});

  final ScanPhase phase;
  final ScanArtifact? artifact;
  final ScanRejection? rejection;
}

final imageSourceGatewayProvider = Provider<ImageSourceGateway>(
  (ref) => PluginImageSourceGateway(),
);

final scanSessionProvider = NotifierProvider<ScanSession, ScanSessionState>(
  ScanSession.new,
);

class ScanSession extends Notifier<ScanSessionState> {
  @override
  ScanSessionState build() => const ScanSessionState(phase: ScanPhase.idle);

  Future<void> pickAndPrepare({
    required bool fromCamera,
    required BuildContext context,
  }) async {
    state = const ScanSessionState(phase: ScanPhase.capturing);
    final gateway = ref.read(imageSourceGatewayProvider);
    final picked = await gateway.pick(fromCamera: fromCamera);
    if (picked == null) {
      _backToIdle();
      return;
    }
    if (!context.mounted) {
      _backToIdle();
      return;
    }
    state = const ScanSessionState(phase: ScanPhase.cropping);
    final cropped = await gateway.crop(picked, context: context);
    if (cropped == null) {
      _backToIdle();
      return;
    }
    final result = cleanScheduleImage(cropped);
    switch (result) {
      case CleanScheduleImage(:final artifact):
        state = ScanSessionState(phase: ScanPhase.consent, artifact: artifact);
      case RejectedScheduleImage(:final reason):
        state = ScanSessionState(phase: ScanPhase.failed, rejection: reason);
    }
  }

  /// Declining consent (or discarding a prepared image) drops the photo
  /// immediately — nothing is retained (docs/architecture/ai-import.md).
  void discard() => _backToIdle();

  void consent() {
    if (state.phase == ScanPhase.consent && state.artifact != null) {
      state = ScanSessionState(
        phase: ScanPhase.ready,
        artifact: state.artifact,
      );
    }
  }

  void restart() => _backToIdle();

  void _backToIdle() => state = const ScanSessionState(phase: ScanPhase.idle);
}
