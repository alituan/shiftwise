import { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { BlurView } from 'expo-blur';
import { blur } from '@/design/tokens';

/**
 * Three flat layers, not one view carrying blur+color+border together:
 *
 *   outer View   -- owns rounded corners, overflow:hidden, and the crisp
 *                   1px border, on an UNBLURRED layer so the stroke and
 *                   clip stay sharp
 *   BlurView     -- absolutely filled, contributes ONLY blur -- no color,
 *                   no border. Putting a backgroundColor on the same node
 *                   as the native blur causes Android compositing
 *                   artifacts and corner-clipping glitches; static style
 *                   only, not a className, since it never varies
 *   inner View   -- the semi-transparent tint + padding, rendered last so
 *                   it visually sits on top of the blur
 *
 * See the PR description for the fuller rationale.
 */
export function GlassCard({ children }: { children: ReactNode }) {
  return (
    <View className="rounded-2xl overflow-hidden border border-surface-border">
      <BlurView intensity={blur.glassCardIntensity} tint="dark" style={StyleSheet.absoluteFill} />
      <View className="bg-surface p-md">{children}</View>
    </View>
  );
}
