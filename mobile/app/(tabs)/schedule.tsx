import { ScrollView, Text, View } from 'react-native';

// Phase 1 placeholder — answers "when's my next shift" in one glance once
// wired to real data. See docs/design/screens.md (Schedule screen spec).
export default function ScheduleScreen() {
  return (
    <ScrollView className="flex-1 bg-surface" contentContainerClassName="p-md gap-lg">
      <View className="gap-2xs">
        <Text className="text-label text-ink-muted">NEXT SHIFT</Text>
        <Text className="text-hero font-semibold text-primary">No shifts yet</Text>
        <Text className="text-body text-ink-muted">Add one or scan a schedule photo.</Text>
      </View>
      <View className="border-t border-hairline pt-md">
        <Text className="text-title font-semibold text-ink">This week</Text>
        <Text className="text-body text-ink-muted mt-xs">Nothing scheduled.</Text>
      </View>
    </ScrollView>
  );
}
