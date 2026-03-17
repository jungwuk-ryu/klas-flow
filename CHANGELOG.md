## Unreleased

- Added an explicit engineering quality baseline document covering CI gates, test policy, and release criteria.
- Added an operations readiness guide covering release dashboards, telemetry signals, and incident response.

## 1.2.0 - 2026-03-08

- Added high-level QR attendance APIs:
  - `KlasAttendanceFeature.qrCheckIn(...)`
  - `KlasAttendanceFeature.qrCheckInRaw(...)`
  - `KlasCourse.qrCheckIn(...)`
- Added course and attendance lookup helpers:
  - `KlasUser.findCourseById(...)`
  - `KlasUser.findCourseByTitle(...)`
  - `KlasAttendanceFeature.findSubjectItemById(...)`
  - `KlasAttendanceFeature.findSubjectItemByTitle(...)`
- Tightened QR attendance target matching to avoid ambiguous course selection.
- Fixed transport handling so JSON API errors are not misclassified as session expiration.
- Refined docs and operation guides:
  - Added live feature coverage documentation.
  - Added AGENTS, PLANS, and CONTRIBUTING documents.
  - Updated README, wiki, Flutter integration, and testing/release docs.

## 1.1.0 - 2026-03-05

- BREAKING: Restructured the public API around domain objects.
  - `login()` return type changed from `Future<void>` to `Future<KlasUser>`.
  - Introduced `KlasUser`, `KlasCourse`, and feature methods.
  - Removed `client.endpoints.*`, `client.api.call*`, `loginAndBootstrap()`, and `setContext()`.
- Bound lecture context to `KlasCourse` to make course-scoped calls consistent.
- Simplified the quality pipeline:
  - Removed typed endpoint generation/verification from `tool/check_all.dart`.
  - Removed low-level generator artifacts (`generate_typed_endpoints.dart`, `typed_endpoints.dart`).
- Refreshed docs and examples:
  - Updated README, tutorials, FAQ, Flutter guide, and migration docs.
  - Reworked the example app to a `user -> course` flow.

## 1.0.0

- Initial release of high-level APIs centered on `KlasClient`.
- Implemented multi-step login orchestration.
- Implemented session cookie management and expiration handling.
- Implemented automatic course-context initialization and injection.
- Implemented transport separation for JSON, HTML, and file responses.
- Implemented exception hierarchy and model layers.
- Added mock-based test suite and met the 80%+ coverage target.
