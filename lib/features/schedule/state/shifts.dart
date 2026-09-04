/// Guest-mode shift list. Phase 1 is local-only and in-memory: state resets
/// on app restart by design (Phase 2 brings Firestore offline persistence).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shiftwise/domain/schedule/shift.dart';

part 'shifts.g.dart';

@Riverpod(keepAlive: true)
class Shifts extends _$Shifts {
  @override
  List<Shift> build() => [];

  void add(Shift shift) => state = [...state, shift];

  void update(Shift shift) => state = [
    for (final existing in state)
      if (existing.id == shift.id) shift else existing,
  ];

  void remove(String id) => state = [
    for (final existing in state)
      if (existing.id != id) existing,
  ];
}
