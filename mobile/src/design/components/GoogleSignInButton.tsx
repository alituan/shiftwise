import { Pressable, StyleSheet, Text, View } from 'react-native';
import { BlurView } from 'expo-blur';
import { blur, fonts } from '@/design/tokens';
import { GoogleLogo } from '@/design/components/GoogleLogo';

export interface GoogleSignInButtonProps {
  onPress: () => void;
}

/** Same glass-card composition as GlassCard: unblurred outer shell, static blur layer, tinted top layer. */
export function GoogleSignInButton({ onPress }: GoogleSignInButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel="Continue with Google"
      className="w-full rounded-2xl overflow-hidden border border-surface-border"
    >
      <BlurView intensity={blur.glassCardIntensity} tint="dark" style={StyleSheet.absoluteFill} />
      <View className="bg-surface p-md flex-row items-center justify-center gap-sm">
        <GoogleLogo size={18} />
        <Text className="text-ink" style={{ fontFamily: fonts.regular, fontSize: 16 }}>
          Continue with Google
        </Text>
      </View>
    </Pressable>
  );
}
