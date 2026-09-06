import { Pressable, Text } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { animation, dimensions, fonts } from '@/design/tokens';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

export interface PrimaryButtonProps {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  accessibilityLabel?: string;
}

/** Flat electric blue only -- no shadow, no gradient. Press: scale to 0.97, 150ms. */
export function PrimaryButton({
  label,
  onPress,
  disabled,
  accessibilityLabel,
}: PrimaryButtonProps) {
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  return (
    <AnimatedPressable
      onPress={onPress}
      disabled={disabled}
      onPressIn={() => {
        // eslint-disable-next-line react-hooks/immutability -- Reanimated shared values are mutated via `.value` by design (UI-thread state outside React's render cycle), not a React state mutation.
        scale.value = withTiming(animation.primaryButtonPressScale, {
          duration: animation.primaryButtonPressDurationMs,
        });
      }}
      onPressOut={() => {
        // eslint-disable-next-line react-hooks/immutability -- see onPressIn above.
        scale.value = withTiming(1, { duration: animation.primaryButtonPressDurationMs });
      }}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel ?? label}
      accessibilityState={{ disabled: !!disabled }}
      style={[{ height: dimensions.primaryButtonHeight }, animatedStyle]}
      className="w-full rounded-button bg-primary items-center justify-center"
    >
      <Text className="text-ink text-base" style={{ fontFamily: fonts.bold, fontSize: 16 }}>
        {label}
      </Text>
    </AnimatedPressable>
  );
}
