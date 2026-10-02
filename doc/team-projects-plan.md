# Team project read API plan

## Goal and success criteria

Expose course-bound team project lists, details, team members and downloadable
attachment metadata through typed APIs. A course with no projects returns an
empty list. Invalid responses and unavailable projects remain distinct from an
empty result.

## Scope

Add `course.teamProjects.listProjects()`, `getDetail(project)` and
`listMembers(project)`. Read project titles, ordinary and additional submission
periods, submission status, published-submission visibility, instructions,
submission text, scores, instructor feedback and team member information when
KLAS provides them. Load instructor, submitted and feedback attachments through
the existing file feature. An `includeFiles: false` detail option allows callers
to read text without fetching attachment metadata.

Keep the existing `course.learning.teamProjects()` learning-status API compatible.
Do not add submission, file upload, team editing, other teams' submissions or
project discussion-board writes. CLI commands and Flutter screens are outside
this SDK change.

## Public API and models

Export `KlasTeamProject`, `KlasTeamProjectDetail`,
`KlasTeamProjectSubmission`, `KlasTeamProjectMember` and
`KlasTeamProjectSubmissionVisibility` from the public package entrypoint.
Models expose application fields without raw endpoint payloads. Unknown optional
values stay null, source text keeps its line breaks, and collections are
immutable. A project reference carries its course and term; detail and member
reads re-resolve the project from its bound course before sending identifiers.
Reject another course's reference before any request. A removed/inaccessible
project raises `TeamProjectUnavailableException`; missing submitted work stays
null. Team member reads return an empty list when no team has been assigned.

## Changed surfaces

- Internal read API/parser and public models under `lib/src`.
- Course feature routing and the domain executor.
- Public exports and exceptions.
- A synthetic fixture and focused tests, plus both canonical high-level suites.
- The team project tutorial, wiki home/index, README, changelog and feature matrix.

## Validation and evidence

Read the official authenticated project, detail and member page logic, using the
linked KLAS Helper source as corroboration for list requests. Keep source captures
and the reference checkout outside the repository. Run
`dart analyze lib test tool`, focused tests and `dart run tool/check_all.dart`.
Test context isolation, empty results, malformed responses, duplicate/removed
references, missing teams/submissions/files, date and flag mapping, attachment
storage selection and binary downloads. Validate the actual SDK with existing
CLI authentication using a guarded read-only probe; the current account has no
projects, so populated results and detail/member/file behavior require synthetic
tests. Commit and push the tested feature branch for review.

## Security and live constraints

Use only list/detail/member/file read calls. Do not submit projects, change teams
or invoke upload/delete/save operations. Do not manufacture a live project
identifier when the account has none. Keep credentials in memory and print only
counts and response-shape diagnostics. Do not store live response data, team
member identities, account identifiers, cookies or downloaded account files.

## Completed validation

On 2026-10-03, scoped analysis and the three focused/high-level suites passed
(82 tests). The full CI-aligned check passed with 227 tests and the prepublish
safety gate. The change adds 37 focused team-project cases and two canonical
public-API regression cases. The guarded SDK probe used existing CLI credentials
in memory and returned HTTP 200 with empty project lists for all six current-term
courses. It performed 14 requests, including six project-list reads, with zero
blocked requests. Populated projects, details, members and attachments were
verified with synthetic HTTP data. No live detail identifiers were invented and
no project submission or team changes were made.
