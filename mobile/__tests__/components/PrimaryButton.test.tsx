import { fireEvent, render, screen } from '@testing-library/react-native';
import { PrimaryButton } from '@/design/components/PrimaryButton';

describe('PrimaryButton', () => {
  it('renders the given label', async () => {
    await render(<PrimaryButton label="Continue" onPress={() => {}} />);
    expect(screen.getByText('Continue')).toBeTruthy();
  });

  it('calls onPress when tapped', async () => {
    const onPress = jest.fn();
    await render(<PrimaryButton label="Continue" onPress={onPress} />);
    await fireEvent.press(screen.getByRole('button'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('exposes an accessible role and label', async () => {
    await render(
      <PrimaryButton
        label="Continue"
        onPress={() => {}}
        accessibilityLabel="Continue to next step"
      />,
    );
    expect(screen.getByRole('button', { name: 'Continue to next step' })).toBeTruthy();
  });

  it('reflects a disabled state to accessibility tooling', async () => {
    await render(<PrimaryButton label="Continue" onPress={() => {}} disabled />);
    const button = screen.getByRole('button');
    expect(button.props.accessibilityState.disabled).toBe(true);
  });
});
