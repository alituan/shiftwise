import { Pressable, StyleSheet, Text, View } from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSequence,
  withSpring,
} from 'react-native-reanimated';
import { LucideIcon } from 'lucide-react-native';
import { animation, blur, colors, dimensions, fonts } from '@/design/tokens';

export interface BottomNavTab {
  key: string;
  label: string;
  icon: LucideIcon;
}

export interface BottomNavProps {
  tabs: BottomNavTab[];
  activeKey: string;
  onTabPress: (key: string) => void;
}

/**
 * Same three-layer composition as GlassCard (see its header comment): the
 * outer bar owns the top hairline border and fixed height on an unblurred
 * layer, BlurView is absolutely filled behind with no color of its own,
 * and the tint + tab row sit in the last (topmost) layer.
 */
export function BottomNav({ tabs, activeKey, onTabPress }: BottomNavProps) {
  const insets = useSafeAreaInsets();

  return (
    <View
      style={{ height: dimensions.bottomNavHeight + insets.bottom }}
      className="border-t border-bottom-nav-border"
    >
      <BlurView intensity={blur.bottomNavIntensity} tint="dark" style={StyleSheet.absoluteFill} />
      <View
        style={{ paddingBottom: insets.bottom }}
        className="flex-1 flex-row bg-bottom-nav-background"
      >
        {tabs.map((tab) => (
          <NavTab
            key={tab.key}
            tab={tab}
            active={tab.key === activeKey}
            onPress={() => onTabPress(tab.key)}
          />
        ))}
      </View>
    </View>
  );
}

function NavTab({
  tab,
  active,
  onPress,
}: {
  tab: BottomNavTab;
  active: boolean;
  onPress: () => void;
}) {
  const scale = useSharedValue(1);
  const Icon = tab.icon;

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const handlePress = () => {
    // Press feedback only -- active/inactive state itself is color-only,
    // per spec ("no pill, no background"). Every tap runs this, whether
    // or not it changes the active tab.
    // eslint-disable-next-line react-hooks/immutability -- Reanimated shared values are mutated via `.value` by design.
    scale.value = withSequence(withSpring(animation.tabIconScalePeak), withSpring(1));
    onPress();
  };

  return (
    <Pressable
      onPress={handlePress}
      accessibilityRole="button"
      accessibilityLabel={tab.label}
      accessibilityState={{ selected: active }}
      className="flex-1 items-center justify-center"
    >
      <Animated.View style={animatedStyle}>
        <Icon size={dimensions.iconSize} color={active ? colors.ink : colors.bottomNavInactive} />
      </Animated.View>
      {active && (
        <Text className="text-ink mt-2xs" style={{ fontFamily: fonts.regular, fontSize: 11 }}>
          {tab.label}
        </Text>
      )}
    </Pressable>
  );
}
