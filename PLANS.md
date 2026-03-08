# PLANS.md

Use a written plan for work that can easily drift across code, tests, docs, and release policy.

## Create a plan when

- the task changes a public API or typed model
- the task affects auth, session renewal, transport, or parsing behavior
- the task touches more than one of `lib/src`, `test`, `wiki/docs`, `example`, or `tool`
- the task changes release, safety, or publishing policy
- the task has migration risk, rollback concerns, or behavior ambiguity

Skip a written plan for small localized fixes, typo/docs-only edits, or narrow test maintenance.

## Required plan sections

Every plan should be decision-complete and include:

1. Goal and success criteria
2. In-scope and out-of-scope behavior
3. Public API or model changes
4. Files or surfaces that must change
5. Validation commands and acceptance criteria
6. Security, live-test, or release constraints

## `klasflow`-specific checklist

### Public API work

- identify the public entrypoint (`KlasClient`, `KlasUser`, `KlasCourse`, or feature object)
- define typed return models and exceptions
- update `test/high_level_api_test.dart`
- update `test/high_level_feature_coverage_test.dart` if the feature is public
- update the matching wiki page and `wiki/14-high-level-api-index.md`
- update `docs/live_feature_coverage.md` when the public capability matrix changes

### Auth/session/transport work

- document expected failure modes
- confirm retry/session-renew behavior
- call out any live-account risk before testing

### Safety/release work

- document blocked artifacts or private-data rules
- include `tool/prepublish_check.dart` impact
- note whether README, wiki, or release checklist must change
