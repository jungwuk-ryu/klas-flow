# AGENTS.md

## Scope

This subtree is the Flutter demo app for `klasflow`. It is not the canonical implementation surface for the library itself.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Windows desktop prerequisites are documented in [`README.md`](README.md).

## Subtree rules

- Prefer edits in `example/lib/` and `example/test/`.
- Do not edit generated build output or platform ephemeral files.
- Keep the demo focused on read-only high-level flows. Do not add state-changing live flows such as QR attendance unless the task explicitly requires a controlled demo change.
- If a library API change breaks the demo, update this subtree only after the root library API and tests are settled.
- Web login failures are often caused by browser cookie policy with the default KLAS origin. Do not treat that as a library bug until the same flow fails on Android, iOS, or desktop.
