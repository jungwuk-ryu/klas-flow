# Develop integration plan

## Goal and success criteria

Merge the six requested SDK branches into develop, verify the integrated feature
set and CLI compatibility, push develop, and remove merged local and remote
feature branches without losing commits.

## Scope

Integrate commit-range checks, captcha login, QR attendance, monthly schedules,
online/E-class video APIs and syllabus lookup. Preserve develop's branch policy
and reconcile its previous calendar fix with the newer verified monthly behavior.
Enable the existing CI gate on develop pushes. Do not publish a package release
or promote master. CLI source and its branch structure are outside this merge;
validate that it can consume the integrated SDK in a separate temporary checkout.

## API and changed surfaces

No new public API is planned. Resolve integration conflicts in SDK domain logic
and canonical tests, preserve the six feature implementations, and update CI and
validation documentation where needed. Use an integration branch based on the
latest remote develop, then advance develop only after local verification.

## Merge sequence

1. codex/fix-commit-message-range
2. codex/feat-captcha-login
3. codex/feat-mobile-qr-attendance
4. codex/fix-monthly-calendar
5. codex/feat-video-playback
6. codex/feat-syllabus

Keep the existing feature commits and record individual merge commits. Before
cleanup, verify that every source branch tip is an ancestor of pushed develop.
Delete remote branches using leases tied to the verified source revisions.

## Validation

- Run `dart run tool/check_all.dart` on the integrated SDK.
- Validate the commit range from the original develop revision to the new tip.
- Run the CLI analysis/test/schema/installer/publish dry-run gate and compile its
  executable with a temporary path override to the integrated SDK.
- Use existing CLI authentication for read-only live checks of monthly schedules,
  course/attendance lists, syllabus and online/E-class media discovery.
- Verify the pushed develop revision, GitHub CI result and branch cleanup.

## Security and live constraints

Keep credentials in memory, reuse the user's authorized local auth session, and
print aggregate results only. Use synthetic tests for captcha continuation, QR
submission, additional verification and playback progress writes. Do not send
email/OTP challenges, submit attendance or record live learning progress. Store
temporary probe source and CLI snapshots outside the repositories; never commit
private response contents, media addresses or credentials.

## Validation results

All six feature tips are ancestors of the integration branch, with one merge
commit per requested branch. Develop's documentation and integration policy are
preserved. QR conflicts were caused by older formatting overlapping the new
verification/session implementation; the new implementation and its tests remain
intact. The older six-week table range helper was replaced by the newer verified
month range used by both calendar APIs, including explicit range overrides.

The SDK CI-aligned gate passed: scoped analysis, 188 tests and release safety
checks. The CLI temporary copy passed its full gate against the integrated SDK
and compiled to a Windows executable. Its real monthly command returned 10
events with complete periods, including 5 that cross month boundaries.

Live SDK reads verified 6 current-term courses, 6 syllabi, 6 attendance subjects
with automatic mobile identification, 10 monthly events, 67 online video entries
and 3 E-class recordings. E-class media discovery returned an MP4 source with a
positive duration and HEAD status 200. The guarded client performed 62 reads,
with no blocked requests, attendance submissions, progress writes or additional
verification writes. Captcha continuation and state-changing behavior were
validated by synthetic tests. No live response data or credentials were stored.

The new-commit convention check passed for the 12 integration and source
commits. Run it again after the final integration documentation/CI commit. After
local validation, advance and push develop, confirm the remote CI gate, then
delete only the merged branches whose remote revisions still match the audit.
