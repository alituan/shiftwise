import { forwardRef, ReactNode, useCallback } from 'react';
import BottomSheet, {
  BottomSheetBackdrop,
  BottomSheetBackdropProps,
  BottomSheetView,
} from '@gorhom/bottom-sheet';
import { colors, radii, dimensions } from '@/design/tokens';

export interface AppBottomSheetProps {
  snapPoints: (string | number)[];
  children: ReactNode;
  onClose?: () => void;
}

/**
 * Themed wrapper around @gorhom/bottom-sheet's BottomSheet. Requires the
 * app root to be wrapped in GestureHandlerRootView (see app/_layout.tsx) --
 * gorhom's gestures don't work without it.
 */
export const AppBottomSheet = forwardRef<BottomSheet, AppBottomSheetProps>(function AppBottomSheet(
  { snapPoints, children, onClose },
  ref,
) {
  const renderBackdrop = useCallback(
    (props: BottomSheetBackdropProps) => (
      <BottomSheetBackdrop
        {...props}
        appearsOnIndex={0}
        disappearsOnIndex={-1}
        opacity={0.6}
        pressBehavior="close"
      />
    ),
    [],
  );

  return (
    <BottomSheet
      ref={ref}
      index={-1}
      snapPoints={snapPoints}
      enablePanDownToClose
      onClose={onClose}
      backdropComponent={renderBackdrop}
      backgroundStyle={{ backgroundColor: colors.bottomSheetSurface }}
      handleIndicatorStyle={{
        backgroundColor: colors.bottomSheetHandle,
        width: dimensions.bottomSheetHandleWidth,
        height: dimensions.bottomSheetHandleHeight,
        borderRadius: radii.bottomSheetHandle,
      }}
      handleStyle={{
        borderTopWidth: 1,
        borderTopColor: colors.bottomSheetBorder,
        borderTopLeftRadius: radii.card,
        borderTopRightRadius: radii.card,
      }}
    >
      <BottomSheetView style={{ flex: 1 }}>{children}</BottomSheetView>
    </BottomSheet>
  );
});
