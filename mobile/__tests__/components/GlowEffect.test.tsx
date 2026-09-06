import { render } from '@testing-library/react-native';
import { GlowEffect } from '@/design/components/GlowEffect';
import { glow } from '@/design/tokens';

describe('GlowEffect', () => {
  it('renders without crashing', async () => {
    const result = await render(<GlowEffect />);
    expect(result.toJSON()).toBeTruthy();
  });

  it("uses the spec'd 280x280 size and center/edge colors from tokens", () => {
    expect(glow.size).toBe(280);
    expect(glow.centerColor).toBe('rgba(59,110,248,0.45)');
    expect(glow.edgeColor).toBe('transparent');
  });
});

describe('GlowEffect — degrades gracefully if react-native-svg fails', () => {
  it('renders nothing instead of crashing when Svg throws during render', async () => {
    jest.resetModules();
    jest.doMock('react-native-svg', () => {
      const actual = jest.requireActual('react-native-svg');
      return {
        ...actual,
        Svg: () => {
          throw new Error('simulated native RadialGradient failure');
        },
      };
    });
    // Silence the expected console.error noise from React's error-boundary logging.
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});

    const { GlowEffect: GlowEffectWithMockedSvg } = require('@/design/components/GlowEffect');
    const result = await render(<GlowEffectWithMockedSvg />);

    expect(result.toJSON()).toBeNull();

    consoleError.mockRestore();
    jest.dontMock('react-native-svg');
    jest.resetModules();
  });
});
