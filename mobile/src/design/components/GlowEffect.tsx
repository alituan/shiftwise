import { Component, ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import Svg, { Defs, RadialGradient, Rect, Stop } from 'react-native-svg';
import { glow } from '@/design/tokens';

/**
 * The glow is decorative only -- if react-native-svg's native RadialGradient
 * fails to render for any reason (missing native module, platform quirk),
 * it must degrade to rendering nothing, never crash the screen it's on.
 * React error boundaries require a class component; there's no hook
 * equivalent for catching render errors in children.
 */
class GlowErrorBoundary extends Component<{ children: ReactNode }, { hasError: boolean }> {
  constructor(props: { children: ReactNode }) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  render() {
    if (this.state.hasError) {
      return null;
    }
    return this.props.children;
  }
}

/**
 * Ambient radial glow behind hero content. Implemented with react-native-svg
 * (not expo-linear-gradient): expo-linear-gradient is a linear-only API and
 * cannot produce a true center-to-edge radial falloff, whereas
 * react-native-svg's RadialGradient does this natively and is the more
 * accurate implementation of "radial" per spec.
 *
 * Positioned top-center behind hero content -- render this as the first
 * child of a `relative` container, with the hero text as a sibling after
 * it (so it paints behind, per standard stacking order), e.g.:
 *
 *   <View className="relative items-center">
 *     <GlowEffect />
 *     <Hero>...</Hero>
 *   </View>
 */
export function GlowEffect() {
  return (
    <GlowErrorBoundary>
      <View pointerEvents="none" style={[StyleSheet.absoluteFill, { alignItems: 'center' }]}>
        <Svg width={glow.size} height={glow.size} style={{ position: 'absolute', top: 0 }}>
          <Defs>
            <RadialGradient id="heroGlow" cx="50%" cy="50%" r="50%">
              <Stop offset="0%" stopColor={glow.centerColor} />
              <Stop offset="100%" stopColor={glow.edgeColor} />
            </RadialGradient>
          </Defs>
          <Rect width={glow.size} height={glow.size} fill="url(#heroGlow)" />
        </Svg>
      </View>
    </GlowErrorBoundary>
  );
}
