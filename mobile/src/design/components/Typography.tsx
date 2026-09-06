import { Text, TextProps } from 'react-native';
import { fonts, typography } from '@/design/tokens';

/**
 * Typed typography scale. `numeric` forces tabular figures -- use it on
 * every time/hours/money display so digits don't shift width as they
 * change (docs/design/tokens.md: "~80% of this app is numbers").
 */
interface ScaleTextProps extends TextProps {
  numeric?: boolean;
}

function tabularStyle(numeric: boolean | undefined) {
  return numeric ? { fontVariant: ['tabular-nums' as const] } : undefined;
}

export function Hero({ style, numeric, ...props }: ScaleTextProps) {
  return (
    <Text
      {...props}
      style={[
        {
          fontFamily: fonts.bold,
          fontSize: typography.hero.fontSize,
          color: typography.hero.color,
        },
        tabularStyle(numeric),
        style,
      ]}
    />
  );
}

export function Title({ style, numeric, ...props }: ScaleTextProps) {
  return (
    <Text
      {...props}
      style={[
        {
          fontFamily: fonts.bold,
          fontSize: typography.title.fontSize,
          color: typography.title.color,
        },
        tabularStyle(numeric),
        style,
      ]}
    />
  );
}

export function Body({ style, numeric, ...props }: ScaleTextProps) {
  return (
    <Text
      {...props}
      style={[
        {
          fontFamily: fonts.regular,
          fontSize: typography.body.fontSize,
          color: typography.body.color,
        },
        tabularStyle(numeric),
        style,
      ]}
    />
  );
}

export function Secondary({ style, numeric, ...props }: ScaleTextProps) {
  return (
    <Text
      {...props}
      style={[
        {
          fontFamily: fonts.regular,
          fontSize: typography.secondary.fontSize,
          color: typography.secondary.color,
        },
        tabularStyle(numeric),
        style,
      ]}
    />
  );
}

export function Label({ style, numeric, ...props }: ScaleTextProps) {
  return (
    <Text
      {...props}
      style={[
        {
          fontFamily: fonts.regular,
          fontSize: typography.label.fontSize,
          color: typography.label.color,
        },
        tabularStyle(numeric),
        style,
      ]}
    />
  );
}
