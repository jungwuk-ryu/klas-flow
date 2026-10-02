# Captcha login continuation

## Goal and success criteria

When KLAS requires its numeric captcha, an SDK caller or a human CLI user can view the challenge and submit an answer within the same HTTP session. Captcha requests and rejected answers are distinguished from invalid account credentials. Normal login and session renewal remain compatible.

## Verified behavior and scope

The public KLAS login page shows a captcha after three login errors. Its script sends the captcha input through both the preliminary check and login confirmation, refreshes the image, and obtains new login security data for another attempt. We will implement human-provided answers with a default limit of three captcha submissions. No OCR, captcha bypass, deliberate incorrect live login attempts, OTP implementation, or live account mutations are included.

## Public API

Add `KlasClient.login(id, password, onCaptcha: ..., maxCaptchaAttempts: 3)`. Export `KlasCaptchaChallenge` with image bytes and attempt metadata, plus a `KlasCaptchaHandler` callback returning a numeric string or null to cancel. With no handler, continue throwing `CaptchaRequiredException`. Keep leading zeros. Cache only the handler and limit for automatic session renewal; do not cache images or answers.

## Implementation surfaces

SDK: login models/exports, auth API, auth flow, session coordinator, login parser, canonical high-level tests, login/session wiki, API index, feature coverage, changelog. CLI: a temporary-image captcha prompter, authenticated service integration, error contract, tests, README/agent docs/decision log. The CLI requires the new SDK version; local development uses an ignored sibling SDK override, and release must publish the SDK first.

## Validation and failure modes

Run SDK `dart analyze lib test tool`, targeted tests, and `dart run tool/check_all.dart`. Run the CLI's full gate and compile its executable. Cover PEM and legacy login, count and confirmation challenges, answer/cookie propagation, rejected answers, cancellation, missing handlers, bad numeric input, retry bounds, image/network failures, invalid passwords, context-preserving renewal, stdout/stderr separation, and saved credential preservation.

## Constraints

Authentication changes stay on their own SDK feature branch. Preserve the prior CLI course-detail changes. Use mock HTTP for challenge flows and temporary test images. Public login code is inspected without logging in; do not trigger captcha or account lockout with deliberate bad passwords. CLI images are temporary, locally opened for the user, and cleaned up. Non-interactive/JSON reads return a dedicated actionable captcha error without prompting. No credentials, answers, tokens, or server source artifacts enter repository logs or fixtures.
