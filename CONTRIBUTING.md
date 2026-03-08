# Contributing to klasflow

## Goal

`klasflow` is a high-level Dart SDK for KLAS. Contributions should improve typed, app-facing SDK behavior without exposing low-level endpoint details or private research materials.

## Workflow

1. Start from the latest `master`.
2. Create a short-lived branch for one focused change.
3. Implement the change in `lib/src` and expose public API only through `lib/klasflow.dart` and `lib/klas_client.dart` when needed.
4. Update tests and docs that match the scope of the change.
5. Validate the change with the appropriate commands.
6. Merge only when the branch is in a releasable state.

## Branch strategy

- `master`
  - Keep it releasable.
  - Do not commit directly to `master` for normal development.
- Branch prefixes
  - `feat/...`: new public capability, new typed model, or additive SDK behavior
  - `fix/...`: behavior bug, parser bug, transport/auth/session bug
  - `docs/...`: README, wiki, docs, guides, agent guidance
  - `chore/...`: tooling, release policy, repository hygiene
  - `refactor/...`: internal structure changes without intended behavior changes
  - `test/...`: test-only changes
- Keep branches small and short-lived.
- Split unrelated work into separate branches instead of batching broad edits together.
- Treat transport, auth, session, and state-changing API changes as isolated work even when the code diff is small.

## Commit guidance

- Use focused commits with clear scopes.
- Recommended format:

```text
type(scope): summary
```

Examples:

```text
feat(attendance): add typed qr attendance check-in
fix(transport): avoid session heuristic on json api errors
docs(repo): improve agent readiness guidance
chore(security): block private research artifacts from release flow
```

- Do not mix unrelated fixes in one commit.
- Keep docs-only and tooling-only changes separate from behavior changes unless they are required to land together.

## Validation rules

Use the smallest validation set that still matches the risk of the change.

### Root bootstrap

```bash
dart pub get --no-example
```

### Standard library gate

```bash
dart analyze lib test tool
dart test
dart run tool/check_all.dart
```

### Release and safety checks

```bash
dart run tool/prepublish_check.dart
```

### Scope-specific expectations

- `lib/src` logic or model changes
  - Run targeted tests at minimum.
  - Run `dart analyze lib test tool` when the change affects shared behavior.
- Public API changes
  - Update `test/high_level_api_test.dart`.
  - Update `test/high_level_feature_coverage_test.dart` when the public surface changes.
  - Update the matching wiki page.
  - Update `wiki/14-high-level-api-index.md`.
  - Update `docs/live_feature_coverage.md` when the feature matrix changes.
- Transport, auth, or session changes
  - Treat as higher-risk.
  - Validate the directly affected tests before merge.
- `example/` changes
  - Follow `example/AGENTS.md`.

## Documentation rules

- Keep public docs high-level.
- Do not publish low-level endpoint details in README, wiki, examples, or tutorials.
- Keep comments and docs natural. Use English when Korean terminology becomes awkward.
- Update user-facing docs when public API names or behavior change.

## Security and privacy rules

- Never commit private specs, research notes, APK/XAPK artifacts, or reverse-engineering byproducts.
- Do not add secrets, cookies, student IDs, passwords, or tokens to code, docs, logs, screenshots, or tests.
- Treat `.gitignore` and `tool/prepublish_check.dart` as release policy.

## Live testing policy

- Default to Mock HTTP unit tests.
- Live verification must stay read-only.
- Do not use real accounts with state-changing APIs such as create, update, delete, submission, or attendance actions.

## Merge expectations

- Merge only releasable branches.
- Prefer keeping one branch aligned with one change theme.
- If a branch adds a public capability, make sure code, tests, wiki, and coverage docs stay aligned before merge.
