import { createRef } from 'react';
import { render, screen } from '@testing-library/react-native';
import { Text } from 'react-native';
import BottomSheet from '@gorhom/bottom-sheet';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { AppBottomSheet } from '@/design/components/AppBottomSheet';

describe('AppBottomSheet', () => {
  it('renders its children inside a GestureHandlerRootView host', async () => {
    const ref = createRef<BottomSheet>();
    await render(
      <GestureHandlerRootView style={{ flex: 1 }}>
        <AppBottomSheet ref={ref} snapPoints={['50%']}>
          <Text>Sheet content</Text>
        </AppBottomSheet>
      </GestureHandlerRootView>,
    );
    expect(screen.getByText('Sheet content')).toBeTruthy();
  });
});
