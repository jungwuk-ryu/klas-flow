# AGENTS.md

## Repository purpose

`klasflow` is a high-level Dart SDK for KLAS. The public surface is `client -> user -> course -> feature` and the repository is optimized for typed, app-facing APIs rather than low-level endpoint exposure.

## Top-level routing

- `lib/klasflow.dart`, `lib/klas_client.dart`: public entrypoints. Keep public API changes discoverable here.
- `lib/src/`: internal implementation. Endpoint specs, parsers, transport, domain logic, and models live here.
- `test/`: canonical library tests. `high_level_api_test.dart` and `high_level_feature_coverage_test.dart` are the main regression nets for public API work.
- `tool/`: validation and live-read-only utility scripts.
- `wiki/`: Korean tutorials and API usage guides. Update when public API shape changes.
- `docs/`: release, coverage, architecture, and integration notes.
- `example/`: Flutter demo app. This subtree has different tooling and its own guidance in [`example/AGENTS.md`](example/AGENTS.md).

## Working rules

- Keep the repository focused on high-level SDK behavior.
- Do not expose low-level endpoint details in README, wiki, examples, or other public-facing docs.
- Never commit private specs, research notes, APK/XAPK artifacts, or reverse-engineering byproducts.
- Keep `lib/src` internal. Public API additions should be surfaced through `lib/klasflow.dart` and/or `lib/klas_client.dart`.
- Write comments and docs in natural sentences. Use English when Korean terminology becomes awkward.

## Branch strategy

- Keep `master` releasable. Do not develop directly on `master`.
- Use short-lived branches named by work type, for example `feat/...`, `fix/...`, `docs/...`, `chore/...`, `refactor/...`, or `test/...`.
- Split unrelated work into separate branches. Do not mix public API work, transport/auth fixes, release policy updates, and docs unless they must ship together.
- Treat transport, auth, session, and state-changing API changes as higher-risk work. Keep those changes isolated and validate them before merge.
- Reverse-engineering and private research stay outside the repository. Only merge the resulting SDK behavior, tests, and public docs.
- See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the human workflow.

## Canonical commands

### Root bootstrap

```bash
dart pub get --no-example
```

### Library validation

```bash
dart analyze lib test tool
dart test
dart run tool/check_all.dart
dart run tool/prepublish_check.dart
```

- `dart run tool/check_all.dart` is the CI-aligned gate.
- Prefer `dart analyze lib test tool` instead of root `dart analyze`. The root repository includes a Flutter example app, so the library gate is intentionally scoped.

### Live account checks

Run only when the task explicitly requires live verification and stay read-only.

```bash
dart run tool/live_smoke.dart
dart run tool/live_account_scenarios.dart
```

Required environment variables:

```bash
KLAS_ID=<id>
KLAS_PASSWORD=<password>
```

## Validation expectations by change type

- `lib/src` logic or models: run `dart analyze lib test tool` and targeted `dart test` at minimum.
- Public API changes: also update the relevant wiki page, [`wiki/14-high-level-api-index.md`](wiki/14-high-level-api-index.md), and [`docs/live_feature_coverage.md`](docs/live_feature_coverage.md).
- Release or safety tooling changes: run `dart run tool/prepublish_check.dart`.
- `example/` changes: follow [`example/AGENTS.md`](example/AGENTS.md).

## Safety and no-edit zones

- Do not edit generated or derived paths such as `.dart_tool/`, `coverage/`, `example/build/`, or platform ephemeral output.
- Treat blocked private artifact patterns in `.gitignore` and `tool/prepublish_check.dart` as release policy, not optional guidance.
- Do not use live accounts for state-changing APIs. Mock HTTP tests are the default. Live checks must remain read-only.
- Avoid adding secrets, cookies, student IDs, passwords, or tokens to source, docs, screenshots, or logs.

## Public API change checklist

When adding or changing a public capability:

1. Update internal implementation in `lib/src`.
2. Export or route the public entrypoint from `lib/klasflow.dart` or `lib/klas_client.dart` if needed.
3. Extend `test/high_level_api_test.dart`.
4. Extend `test/high_level_feature_coverage_test.dart` if the feature is part of the public surface.
5. Update the matching wiki tutorial and the high-level API index.
6. Update `docs/live_feature_coverage.md` if the public feature matrix changed.

## Planning expectations

Use [`PLANS.md`](PLANS.md) for work that is risky, cross-cutting, or spans multiple surfaces such as:

- public API additions or breaking behavior changes
- auth/session/transport changes
- work touching both library code and docs/tests/example
- release or security policy changes

Small localized fixes or doc-only edits do not need a written plan.
