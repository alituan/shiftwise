import { fireEvent, render, screen } from '@testing-library/react-native';
import { Home, Scan } from 'lucide-react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { BottomNav } from '@/design/components/BottomNav';

const tabs = [
  { key: 'schedule', label: 'Schedule', icon: Home },
  { key: 'scan', label: 'Scan', icon: Scan },
];

function renderNav(activeKey: string, onTabPress: (key: string) => void) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 0, height: 0 },
        insets: { top: 0, left: 0, right: 0, bottom: 0 },
      }}
    >
      <BottomNav tabs={tabs} activeKey={activeKey} onTabPress={onTabPress} />
    </SafeAreaProvider>,
  );
}

describe('BottomNav', () => {
  it('renders a label only for the active tab', async () => {
    await renderNav('schedule', () => {});
    expect(screen.getByText('Schedule')).toBeTruthy();
    expect(screen.queryByText('Scan')).toBeNull();
  });

  it('calls onTabPress with the pressed tab key', async () => {
    const onTabPress = jest.fn();
    await renderNav('schedule', onTabPress);
    await fireEvent.press(screen.getByRole('button', { name: 'Scan' }));
    expect(onTabPress).toHaveBeenCalledWith('scan');
  });

  it('marks the active tab as selected for accessibility', async () => {
    await renderNav('schedule', () => {});
    const activeTab = screen.getByRole('button', { name: 'Schedule' });
    expect(activeTab.props.accessibilityState.selected).toBe(true);
    const inactiveTab = screen.getByRole('button', { name: 'Scan' });
    expect(inactiveTab.props.accessibilityState.selected).toBe(false);
  });
});
