// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shifts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Shifts)
final shiftsProvider = ShiftsProvider._();

final class ShiftsProvider extends $NotifierProvider<Shifts, List<Shift>> {
  ShiftsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftsHash();

  @$internal
  @override
  Shifts create() => Shifts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Shift> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Shift>>(value),
    );
  }
}

String _$shiftsHash() => r'0ab13df54c9e68fb2b37262a728b7db3d7c568da';

abstract class _$Shifts extends $Notifier<List<Shift>> {
  List<Shift> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Shift>, List<Shift>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Shift>, List<Shift>>,
              List<Shift>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
