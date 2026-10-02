# Monthly calendar correction

## Goal and success criteria

Read a selected calendar month through the existing high-level attendance APIs.
Return the original start and end dates, including events spanning two months,
so a CLI can reproduce the KLAS monthly schedule list.

## Scope

Fix month-list and month-table date-range defaults and the typed month-table
model. Preserve explicit query ranges, existing day/weekday fields, and the
frame summary API. Attendance writes and timetable behavior are outside scope.

## Public API and models

Add nullable ISO 8601 `startsAt` and `endsAt` strings to
`KlasMonthlyScheduleTableItem`. Unknown or malformed dates remain null;
calendar dates must not silently roll into another day or month.

## Files and surfaces

Update `lib/src/domain/klas_user.dart`, `lib/src/models/high_level_models.dart`,
high-level API/feature coverage and date regression tests, the attendance wiki,
the public API index, and live feature coverage.

## Validation and acceptance

Run `dart analyze lib test tool`, targeted public API/date tests, and
`dart run tool/check_all.dart`. Test explicit/default months, leap February,
December rollover, custom ranges, compact/ISO timestamps, and cross-month events.
Compare a read-only monthly query with the authenticated Chrome calendar.

## Security and release constraints

Use synthetic fixtures. Keep research responses and account/session data outside
Git. Live checks may only read schedules. Commit and push the SDK correction
before pinning that exact revision in the CLI; package publication is separate.

## Completed validation

The full `tool/check_all.dart` gate passed: scoped analysis, 128 tests, and the
prepublish safety check. The authenticated read-only October request returned
200 and the same ten schedule periods as the KLAS screen.
