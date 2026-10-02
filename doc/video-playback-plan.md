# Video lecture playback and progress

## Goal and success criteria

Let a third-party KLAS client list video lectures, obtain authenticated playback
information, resume with an app-owned position, and save actual playback progress through the
high-level SDK. Keep the SDK independent of a camera, browser, player widget,
and CLI. A consumer supplies its player and playback events.

## Scope

Implement the official video content flow and typed playback/progress models.
Implement E-class classroom recording review through its separate media flow;
E-class review does not use online learning progress writes.
Preserve existing learning list methods. Keep academic completion and attendance
subject to KLAS responses and learning periods. No synthetic completion, automatic
watching, or changes to the CLI or Flutter demo are included.

## Public API

Route `listVideoLectures` and `openVideo` through `course.learning` and a typed
playback session. Expose playable media descriptors and explicit player event,
status, and cleanup operations. Consumers keep resume positions in their apps.
Handle email or existing OTP verification with a consumer callback. Route E-class
`listRecordings` and `openVideo` separately through `course.eclass`; return media
without creating an online progress session.
Credentials and private protocol identifiers stay internal to session objects.

## Surfaces

Update internal learning APIs, domain routing, transport only if the verified
protocol requires it, typed models, public exports, canonical high-level tests,
focused playback tests, README, wiki 07, 08 and 14, and feature coverage documentation.

## Validation

Use synthetic HTTP fixtures for playback bootstrap and progress writes. Cover
pause/seek/resume behavior, invalid input, server rejection, session expiration,
concurrency, cleanup, and no automatic replay of ambiguous progress writes.
Run `dart analyze lib test tool`, `dart test`, and `dart run tool/check_all.dart`.
Validate that a custom player can use public imports alone.

## Security, live-test, and release constraints

Inspect authenticated Chrome pages and official player source read-only. Do not
execute video playback or progress writes on the live account during research.
Keep private responses, media links, lecture keys, credentials, and screenshots
out of Git. Store only SDK behavior, synthetic fixtures, and developer usage docs.
Use an isolated feature branch; default-branch merge and publication are separate.

## Status

Implementation and focused mock tests cover playback, verification, separate
E-class media resolution, session interruption, and cookie isolation. Official
online and E-class media metadata and MP4 HEAD responses were verified read-only.
The public SDK APIs resolved both online and E-class media on the live account,
with MP4 HEAD responses of 200 and no progress or verification writes. Synthetic
regression coverage also includes the additional official media description format.
The CI-aligned integration gate passes: scoped analysis, all 160 tests, and release
safety checks. Live progress writes remain excluded.
