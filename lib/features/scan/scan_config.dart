/// Tunables and copy for the client-side scan pipeline. Client validation
/// is privacy and UX speed only — the backend repeats every check
/// (docs/architecture/ai-import.md); nothing here is a security boundary.
library;

/// Placeholder until the owner selects the AI provider (open scope.md
/// launch decision). The consent notice and privacy copy must use this
/// single value so the named processor stays consistent everywhere.
const String aiProcessorName = 'our AI schedule-reading service';

class ScanLimits {
  const ScanLimits({
    this.maxBytes = 15 * 1024 * 1024,
    this.maxPixels = 40000000,
    this.minSide = 200,
  });

  /// Raw picked-file cap, before decoding.
  final int maxBytes;

  /// Decoded pixel cap (40 MP).
  final int maxPixels;

  /// Smallest accepted side — smaller images are unreadable in practice.
  final int minSide;
}
