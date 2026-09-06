import { Pressable, Text } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { animation, fonts } from '@/design/tokens';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

export interface GhostButtonProps {
  label: string;
  onPress: () => void;
  accessibilityLabel?: string;
}

/** Transparent, no border. Press: opacity to 0.6, 100ms. */
export function GhostButton({ label, onPress, accessibilityLabel }: GhostButtonProps) {
  const opacity = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
  }));

  return (
    <AnimatedPressable
      onPress={onPress}
      onPressIn={() => {
        // eslint-disable-next-line react-hooks/immutability -- Reanimated shared values are mutated via `.value` by design (UI-thread state outside React's render cycle), not a React state mutation.
        opacity.value = withTiming(animation.ghostButtonPressOpacity, {
          duration: animation.ghostButtonPressDurationMs,
        });
      }}
      onPressOut={() => {
        // eslint-disable-next-line react-hooks/immutability -- see onPressIn above.
        opacity.value = withTiming(1, { duration: animation.ghostButtonPressDurationMs });
      }}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel ?? label}
      style={animatedStyle}
    >
      <Text className="text-ink-secondary" style={{ fontFamily: fonts.regular, fontSize: 15 }}>
        {label}
      </Text>
    </AnimatedPressable>
  );
}
