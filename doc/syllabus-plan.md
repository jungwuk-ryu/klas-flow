# Course syllabus plan

## Goal and success criteria

Provide a read-only, typed syllabus from a bound undergraduate course. Consumer
applications can display the description, objectives, assessments, textbooks and
weekly plan without opening a browser or constructing request payloads.

## Scope

Include course metadata, instructor and assistant contacts, class times, selected
teaching and delivery methods, recommended courses, learning outcomes, grading,
textbooks, weekly notes and make-up lessons. Resolve shared fixed syllabi where
the official course view uses them. Return null when no syllabus is registered;
report temporary access restrictions and malformed responses separately.

Graduate syllabus search, unregistered-course search, printing, enrollment counts,
department-specific experiment/design supplement tables and CLI commands are
outside this change. Existing CLI commands remain unchanged.

## Public API and models

- Add `Future<KlasSyllabus?> KlasCourse.syllabus()`.
- Export immutable syllabus, instructor, class-time, assessment, textbook, weekly
  plan and learning-outcome models through `klasflow.dart`.
- Keep request paths and response field mapping inside `lib/src`.
- Preserve missing numeric values as null, including assessment percentages;
  preserve multiline text. Do not invent grading percentages or course content.

## Changed surfaces

- Internal syllabus API/parser, domain executor and course entrypoint.
- Public models and exports.
- Synthetic syllabus HTTP fixtures, dedicated tests and both canonical high-level
  API test files.
- Course tutorial, high-level API index, feature coverage, README and changelog.

## Validation and acceptance

- `dart analyze lib test tool` and targeted syllabus/high-level tests.
- `dart run tool/check_all.dart` for the full CI gate.
- Read-only live verification of the public API against the authenticated KLAS
  course screen. Compare aggregate field presence, weekly rows, class times and
  assessment totals; do not log the actual syllabus or course/account identifiers.
- Cover fixed versus ordinary syllabus sources, empty/missing data, closed
  courses, temporary restrictions, response errors and bound course isolation.

## Security and release constraints

No state-changing live requests. Use synthetic data for all committed fixtures.
Do not commit official source pages, research artifacts, credentials, cookies or
live course contents. Keep this additive change on its own branch. Commit and
push after validation; do not publish a package release or merge master.

## Validation results

- `dart run tool/check_all.dart` passed on 2026-10-03: scoped analysis had no
  issues, all 188 tests passed, and prepublish checks passed.
- The dedicated syllabus suite contains 26 tests, with public entrypoint and
  feature reachability also covered by the two canonical API suites.
- The public SDK returned registered syllabi for six current-term courses in a
  read-only account probe. Each contained a summary, objectives and 15 weekly
  entries; each assessment total was 100%. Class times and textbooks were also
  present. The probe used an explicit read-only request allowlist.
- The live account supplied ordinary syllabi. Shared plans were validated with
  synthetic HTTP responses and the official view's documented data mapping in
  implementation code. No official source artifact is included in this change.
