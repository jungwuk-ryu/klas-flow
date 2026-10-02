## 1.3.0 (Unreleased)

- Added typed online video lecture listing, playable MP4/HLS media, and player event integration through `learning.listVideoLectures()`, `learning.openVideo()`, and `KlasVideoPlaybackSession`.
- Persist server-reported progress during observed playback, exclude paused and unobserved gaps, handle email or registered OTP verification, and invalidate replaced sessions without replaying uncertain writes.
- Added E-class recording review through `eclass.listRecordings()` and `eclass.openVideo()`, using its separate playback flow without online learning progress writes.
- Keep players and resume positions in consumer applications, and isolate KLAS cookies from external media metadata requests.

- Automatically apply the mobile app User-Agent to KW attendance requests with ordinary `KlasClient()` configuration.
- Added QR attendance verification callbacks for email and registered OTP, with direct decoded-string submission or separate preparation through `prepareQrCheckIn()` and `KlasQrCheckInSession.submit()`.
- Keep QR input in the calling program, allow local cancellation, and prevent reuse of a prepared submission or use after a login session change.
- Fixed mobile attendance subject identification, certification context, closed-course checks, and success/failure response parsing.
- Prevented automatic session renewal or replay of email delivery, one-time verification, and QR attendance submission requests.

- Added numeric captcha continuation through `KlasClient.login(onCaptcha: ..., maxCaptchaAttempts: ...)` and exported `KlasCaptchaChallenge` / `KlasCaptchaHandler`.
- Preserve the login session when displaying a challenge, refresh rejected challenges within a bounded retry loop, and reuse the handler during automatic session renewal.
- Keep cancellation and missing handlers as captcha errors, distinct from invalid credentials; preserve leading zeros and avoid storing captcha answers or images.

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
