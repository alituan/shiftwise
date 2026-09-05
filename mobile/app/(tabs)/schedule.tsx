import { useMemo, useState } from 'react';
import { Alert, Pressable, ScrollView, Text, TextInput, View } from 'react-native';
import { DateTime } from 'luxon';
import { selectNextShift, useShiftsStore } from '@/features/schedule/shiftsStore';
import { durationMinutes } from '@/domain/time/ShiftInterval';

// Phase 1: manual shift CRUD, local-only (guest) mode, no cloud sync yet.
// See docs/design/screens.md (Schedule screen spec) for the target layout;
// this is the functional core, real design-system components (App*
// equivalents) land in a later design-system phase.
export default function ScheduleScreen() {
  const shifts = useShiftsStore((state) => state.shifts);
  const addShift = useShiftsStore((state) => state.addShift);
  const deleteShift = useShiftsStore((state) => state.deleteShift);
  const [role, setRole] = useState('');

  const nowIso = useMemo(() => DateTime.utc().toISO() as string, []);
  const nextShift = selectNextShift(shifts, nowIso);

  const handleAddShift = () => {
    if (role.trim().length === 0) {
      Alert.alert('Add a role', 'Name the role for this shift (e.g. "Barista").');
      return;
    }
    const start = DateTime.utc()
      .plus({ days: 1 })
      .set({ hour: 14, minute: 0, second: 0, millisecond: 0 });
    const end = start.plus({ hours: 8 });
    addShift({
      startUtc: start.toISO() as string,
      endUtc: end.toISO() as string,
      timeZone: DateTime.local().zoneName,
      jobId: null,
      role: role.trim(),
      paidBreakMinutes: 0,
      unpaidBreakMinutes: 30,
    });
    setRole('');
  };

  return (
    <ScrollView className="flex-1 bg-surface" contentContainerClassName="p-md gap-lg">
      <View className="gap-2xs">
        <Text className="text-label text-ink-muted">NEXT SHIFT</Text>
        {nextShift ? (
          <>
            <Text className="text-hero font-semibold text-primary">{nextShift.role}</Text>
            <Text className="text-body text-ink-muted">
              {DateTime.fromISO(nextShift.startUtc, { zone: 'utc' })
                .setZone(nextShift.timeZone)
                .toFormat('ccc \u00b7 h:mm a')}
            </Text>
          </>
        ) : (
          <>
            <Text className="text-hero font-semibold text-primary">No shifts yet</Text>
            <Text className="text-body text-ink-muted">
              Add one below or scan a schedule photo.
            </Text>
          </>
        )}
      </View>

      <View className="border-t border-hairline pt-md gap-sm">
        <Text className="text-title font-semibold text-ink">Add a shift</Text>
        <TextInput
          className="border border-hairline rounded-md p-sm text-body text-ink"
          placeholder="Role (e.g. Barista)"
          placeholderTextColorClassName="text-ink-muted"
          value={role}
          onChangeText={setRole}
          accessibilityLabel="Shift role"
        />
        <Pressable
          onPress={handleAddShift}
          className="bg-primary rounded-md p-sm items-center"
          accessibilityRole="button"
          accessibilityLabel="Add shift starting tomorrow at 2pm for 8 hours"
        >
          <Text className="text-body font-semibold text-surface">Add tomorrow 2:00-10:00 PM</Text>
        </Pressable>
      </View>

      <View className="border-t border-hairline pt-md gap-sm">
        <Text className="text-title font-semibold text-ink">This week</Text>
        {shifts.length === 0 ? (
          <Text className="text-body text-ink-muted">Nothing scheduled.</Text>
        ) : (
          shifts.map((shift) => (
            <View
              key={shift.id}
              className="flex-row justify-between items-center bg-surface-dim rounded-md p-sm"
            >
              <View>
                <Text className="text-body text-ink">{shift.role}</Text>
                <Text className="text-label text-ink-muted">
                  {DateTime.fromISO(shift.startUtc, { zone: 'utc' })
                    .setZone(shift.timeZone)
                    .toFormat('ccc LLL d \u00b7 h:mm a')}{' '}
                  &middot; {(durationMinutes(shift) / 60).toFixed(1)}h
                </Text>
              </View>
              <Pressable
                onPress={() => deleteShift(shift.id)}
                accessibilityRole="button"
                accessibilityLabel={`Delete ${shift.role} shift`}
                className="p-2xs"
              >
                <Text className="text-critical text-body">Delete</Text>
              </Pressable>
            </View>
          ))
        )}
      </View>
    </ScrollView>
  );
}
