# Engineering Quality Baseline

This document formalizes the rollout baseline for `klasflow`.

## CI Gates (Blocking)

CI is defined in `.github/workflows/ci.yml` and blocks merges when failing.

Required gate command:

- `dart run tool/check_all.dart`

`tool/check_all.dart` currently enforces:

1. dependency install (`dart pub get --no-example`)
2. static analysis (`dart analyze lib test tool`)
3. test suite (`dart test`)
4. release safety scan (`dart run tool/prepublish_check.dart`)

## Test Policy

- Mock-based deterministic tests are the default.
- Public API changes must be covered in:
  - `test/high_level_api_test.dart`
  - `test/high_level_feature_coverage_test.dart` (when surface coverage changes)
- Live account checks are optional, read-only, and never a CI requirement.
- Security and parser-sensitive changes should include regression tests before merge.

## Release Criteria

Before release:

1. CI is green on the release commit.
2. `dart run tool/check_all.dart` passes locally.
3. `doc/release_checklist.md` has been completed.
4. Public-facing docs (`README.md`, wiki, coverage docs) match shipped behavior.
5. `pubspec.yaml` metadata and `CHANGELOG.md` entries are updated together.
