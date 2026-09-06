import { Text, View } from 'react-native';

// Phase 1 placeholder. Real screen: profile, locale/timezone/week-start,
// jobs/rates, notifications, billing, export, consent, account deletion.
export default function SettingsScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-surface p-md gap-xs">
      <Text className="text-title font-semibold text-ink">Settings</Text>
      <Text className="text-body text-ink-muted text-center">Coming soon.</Text>
    </View>
  );
}
