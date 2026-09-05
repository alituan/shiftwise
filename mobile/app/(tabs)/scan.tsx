import { Text, View } from 'react-native';

// Phase 1 placeholder — full pipeline (camera/picker, crop, consent, upload,
// review) is a Phase 3 deliverable. See docs/architecture/ai-import.md.
export default function ScanScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-surface p-md gap-xs">
      <Text className="text-title font-semibold text-ink">Scan a schedule</Text>
      <Text className="text-body text-ink-muted text-center">
        Photo import is coming soon — add shifts manually from Schedule for now.
      </Text>
    </View>
  );
}
