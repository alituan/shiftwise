import { fireEvent, render, screen } from '@testing-library/react-native';
import { GhostButton } from '@/design/components/GhostButton';

describe('GhostButton', () => {
  it('renders the given label', async () => {
    await render(<GhostButton label="Skip" onPress={() => {}} />);
    expect(screen.getByText('Skip')).toBeTruthy();
  });

  it('calls onPress when tapped', async () => {
    const onPress = jest.fn();
    await render(<GhostButton label="Skip" onPress={onPress} />);
    await fireEvent.press(screen.getByRole('button'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('exposes an accessible role', async () => {
    await render(
      <GhostButton label="Skip" onPress={() => {}} accessibilityLabel="Skip this step" />,
    );
    expect(screen.getByRole('button', { name: 'Skip this step' })).toBeTruthy();
  });
});
