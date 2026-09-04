# ShiftWise

Cross-platform (iOS/Android) Flutter app for hourly workers: next shift,
scheduled hours, estimated gross pay. AI-assisted schedule import is always
human-confirmed before it becomes authoritative.

Read `docs/PROJECT_PLAN.md` first — it routes every task to the right doc.
Agent working rules live in `AGENTS.md`; the phase breakdown in
`docs/phases.md`.

## Development

The toolchain is pinned in `mise.toml`:

    mise install
    flutter pub get
    flutter analyze
    dart format --output=none --set-exit-if-changed .
    flutter test

Web is a preview/verification target only — iOS and Android are the shipping
platforms:

    flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0
