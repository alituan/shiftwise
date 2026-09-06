import { fireEvent, render, screen } from '@testing-library/react-native';
import { GoogleSignInButton } from '@/design/components/GoogleSignInButton';

describe('GoogleSignInButton', () => {
  it('renders the expected copy', async () => {
    await render(<GoogleSignInButton onPress={() => {}} />);
    expect(screen.getByText('Continue with Google')).toBeTruthy();
  });

  it('calls onPress when tapped', async () => {
    const onPress = jest.fn();
    await render(<GoogleSignInButton onPress={onPress} />);
    await fireEvent.press(screen.getByRole('button'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('exposes an accessible label matching the visible copy', async () => {
    await render(<GoogleSignInButton onPress={() => {}} />);
    expect(screen.getByRole('button', { name: 'Continue with Google' })).toBeTruthy();
  });
});
