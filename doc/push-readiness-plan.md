# Commit and push readiness

## Goal and success criteria

Push reviewed SDK and CLI changes as focused commits on feature branches. A fresh checkout must resolve the same SDK revision and pass its required checks without a developer's local filesystem. Commit-message validation must inspect the commits introduced by a pull request or push, including rejection of a newly added invalid subject.

## Scope

Fix SDK CI commit selection, preserve existing commit-message conventions, and separate captcha and QR attendance commits. Separate CLI course detail and captcha changes. Connect the CLI development branch to the verified SDK commit through a Git override in its root pubspec, and regenerate its lockfile with no local SDK override. Package publication and default-branch merging are separate release steps.

## Public API and models

Keep the completed captcha and QR string APIs from their feature plans. Add no student-facing features here. The CLI retains its hosted SDK version requirement for publication; the development override pins the pushed SDK commit so source checkouts and CI can run before that package is published.

## Surfaces

SDK CI, a cross-platform commit-message validation tool and tests, and this plan change together on a focused CI branch. SDK captcha and QR code, tests, and public docs remain in their respective feature commits. CLI dependency metadata, release guidance and decision log describe the temporary Git pin and its eventual removal.

## Validation

Test rejection of invalid new commits, exclusion of legacy history, and initial-push handling. Run SDK analysis, tests and prepublish checks. Validate each staged feature snapshot before committing. Run the CLI full gate with its Git dependency and no local override, compile its executable, and check help/schema/dry-run behavior. Push only after local checks pass, verify remote branch hashes, and keep the existing history intact.

## Constraints

Do not rewrite old commits or force-push. Do not commit local SDK paths, compiled outputs, private research, credentials, or live account material. Test attendance and verification writes with mock HTTP only. Keep unrelated changes separate and use the existing feature branches as a stack where commits depend on earlier work.
