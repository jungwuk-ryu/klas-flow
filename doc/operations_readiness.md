# Operations Readiness

This document defines the minimum observability and incident response baseline for the first public release of `klasflow`.

## Primary objectives

- detect upstream KLAS breakage separately from SDK regressions
- catch parser and session failures before consumers ship them downstream
- give maintainers a small, repeatable incident workflow for release and live-read-only issues

## Signals to collect

Collect these signals from CI, live read-only smoke runs, and any hosted integration that wraps `klasflow`.

| Signal | Why it matters | Minimum dimensions |
| --- | --- | --- |
| `sdk.login_attempts_total` | health of the highest-risk entrypoint | `result` |
| `sdk.health_check_failures_total` | early warning for broad breakage | `failure_type` |
| `sdk.request_duration_ms` | performance and upstream slowness | `feature`, `endpoint_group` |
| `sdk.session_refresh_total` | indicates session churn or auth loops | `result` |
| `sdk.parse_failures_total` | catches HTML/API shape drift | `feature` |
| `sdk.live_smoke_failures_total` | release confidence for real accounts | `script` |

Notes:

- `failure_type` should be stable and low-cardinality, for example `auth`, `network`, `parse`, or `upstream_contract`.
- Never emit credentials, student IDs, cookies, or raw payload bodies into telemetry.

## Release dashboard

The first dashboard only needs three views.

### 1. API health

- login success rate
- health-check failure count by `failure_type`
- top failing feature groups

Target:

- login success rate >= 99% in controlled smoke environments

### 2. Latency and parser safety

- p50 and p95 `sdk.request_duration_ms` by feature group
- parse failure trend by feature
- session refresh success/failure ratio

Target:

- parse failures should remain at zero on release candidates

### 3. Release confidence

- latest `tool/check_all.dart` result
- latest `tool/prepublish_check.dart` result
- latest live read-only smoke result and timestamp
- current release candidate version or commit

## Alert thresholds

- page immediately on any parser failure in a release candidate or after release
- page if login success rate falls below 97% for 15 minutes
- page if `sdk.live_smoke_failures_total > 0` after a release candidate is cut
- create a non-paging ticket if p95 request duration doubles for 30 minutes without matching upstream incident context

## Incident checklist

1. Confirm blast radius.
   Check whether the failure affects login, one feature family, or all high-level APIs.
2. Review the dashboard.
   Compare current failure type, request latency, and parser failures with the last known good release.
3. Reproduce with read-only scripts.
   Start with `tool/live_smoke.dart` or `tool/live_account_scenarios.dart` and avoid any state-changing flow.
4. Classify the issue.
   Use one bucket: auth/session, upstream KLAS outage, parser/contract drift, SDK regression, release packaging.
5. Mitigate.
   Roll back the release, pause publication, or temporarily advise consumers to pin the previous version.
6. Communicate.
   Log first seen time, impacted APIs, suspected root cause, mitigation, and owner.
7. Close only after evidence.
   Require green quality gates and a passing live read-only smoke before reopening release work.

## Evidence to capture during incidents

- failing feature or script name
- stable failure type and exception summary
- first observed timestamp
- last known good version or commit
- whether `tool/check_all.dart` and `tool/prepublish_check.dart` still pass
- whether live smoke reproduces the issue consistently

## Exit criteria for first public release

- dashboard panels above exist in the chosen monitoring tool
- alert routing is configured for parser failures, login failures, and smoke failures
- `doc/release_checklist.md` is completed with links to smoke evidence
- incident handling can be executed from this document without relying on private notes
