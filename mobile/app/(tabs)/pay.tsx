import { Text, View } from 'react-native';

// Phase 1 placeholder. Real screen always labels "Estimated gross pay" and
// shows hours/base/differentials/rule-version — see docs/architecture/pay-engine.md.
export default function PayScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-surface p-md gap-xs">
      <Text className="text-title font-semibold text-ink">Estimated gross pay</Text>
      <Text className="text-body text-ink-muted text-center">Coming soon.</Text>
    </View>
  );
}
