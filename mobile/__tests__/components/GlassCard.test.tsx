import { render, screen } from '@testing-library/react-native';
import { Text } from 'react-native';
import { GlassCard } from '@/design/components/GlassCard';

describe('GlassCard', () => {
  it('renders its children', async () => {
    await render(
      <GlassCard>
        <Text>Card content</Text>
      </GlassCard>,
    );
    expect(screen.getByText('Card content')).toBeTruthy();
  });
});
