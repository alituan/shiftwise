import { render, screen } from '@testing-library/react-native';
import { Body, Hero, Label, Secondary, Title } from '@/design/components/Typography';

describe('Typography scale', () => {
  it('renders each scale component with its text', async () => {
    await render(
      <>
        <Hero>Hero text</Hero>
        <Title>Title text</Title>
        <Body>Body text</Body>
        <Secondary>Secondary text</Secondary>
        <Label>Label text</Label>
      </>,
    );
    expect(screen.getByText('Hero text')).toBeTruthy();
    expect(screen.getByText('Title text')).toBeTruthy();
    expect(screen.getByText('Body text')).toBeTruthy();
    expect(screen.getByText('Secondary text')).toBeTruthy();
    expect(screen.getByText('Label text')).toBeTruthy();
  });

  it('forces tabular figures only when numeric is set', async () => {
    await render(
      <>
        <Body testID="plain">$127.88</Body>
        <Body testID="numeric" numeric>
          $127.88
        </Body>
      </>,
    );
    const plain = screen.getByTestId('plain');
    const numeric = screen.getByTestId('numeric');
    const flatten = (style: unknown) =>
      Array.isArray(style) ? Object.assign({}, ...style.filter(Boolean)) : style;
    expect(flatten(plain.props.style).fontVariant).toBeUndefined();
    expect(flatten(numeric.props.style).fontVariant).toEqual(['tabular-nums']);
  });
});
