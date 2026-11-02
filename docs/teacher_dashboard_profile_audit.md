# Teacher Dashboard and Profile Audit

## Scope

This audit covers the teacher dashboard, recent enrollments, quick actions,
financial and payout presentation, teacher profile, and teacher
assessment status filters. The implementation follows `memory/rules.md` and
keeps Supabase access in the data layer.

## Learner count correction (2026-10-24)

The dashboard already counted distinct active/completed learners, but the
teacher roster was empty in Supabase mode and course models hardcoded zero
learners. Migration `20261024030000_teacher_learner_roster.sql` adds teacher-only
per-course counts and a paginated roster that exposes names and enrollment
details, not student email. Course cards/details now use the count query;
View learners uses the roster query with course and name filters. The live
screen does not show the mock-only progress, scores, or activity indicators.

Hosted verification passed: the owner-scoped count and roster queries each
returned one learner for Kashmir Studies, and the cross-teacher/student SQL
authorization test passed. Focused mapper and compact-screen widget tests
passed. Two unrelated existing assertions in `test/widget_test.dart` remain
failing (auth-role login and course-detail tab text); its mock learner test
passed separately.

## Research direction

The review used current instructor and finance dashboard references as pattern
research, not as visual templates:

- [Education Management System Dashboard](https://dribbble.com/shots/26356936-Education-Management-System-Dashboard-UI-UX-Design)
  prioritizes enrollment, course health, pending work, and recent activity.
- [EduFlow Teacher LMS Dashboard](https://dribbble.com/shots/27345877-EduFlow-Teacher-LMS-Dashboard-UI-Design-Education-Web-App)
  emphasizes a small set of task-focused quick actions and legible workload
  summaries.
- [Edtech teacher dashboard](https://dribbble.com/shots/27373042-Edtech-teacher-dashboard)
  highlights clear data hierarchy and actionable next steps rather than
  decorative metrics.
- [Finance Operations Dashboard](https://dribbble.com/shots/27284487-Nesaf-io-Finance-Operations-Dashboard-for-Withdrawals-Sales)
  places available and pending balances first, followed by transaction status
  and history.
- [Withdrawal Processes](https://dribbble.com/shots/25087542-Wink-eCommerce-Dashboard-Withdrawal-Processes)
  keeps balance, verification state, and transaction history together.

Adapted direction: use the existing Inter typography and blue brand color,
reduce competing accent colors, reserve cards for grouped information, make
every dashboard metric/action navigable, and show honest empty states.

## Audit findings

- The dashboard hardcoded the instructor name, avatar, earnings, and three
  enrollment records.
- Live teacher statistics returned zero students even when owned courses had
  enrollments.
- Six visually equal quick-action cards created noise and obscured priority.
- Several summary cards were non-interactive.
- The payout screen displayed invented balances and could report a successful
  withdrawal without a payment provider or backend record.
- Teacher profile showed the email address. Repeating dashboard metrics on the
  profile later proved redundant with Studio overview.
- Quiz and assignment chips remained visible when their datasets were empty,
  and the initial filter could point at an empty status.
- Teacher shell navigation used widget-local `setState`, contrary to project
  rules.

## Implemented design

- The dashboard now uses the authenticated profile, owned course and quiz data,
  privacy-safe enrollment aggregates, and provider-owned finance values.
- A compact teaching summary leads directly to course management.
- Four category-style overview tiles link to learners, courses, assessments,
  and financials.
- Quick actions prioritize course creation with one primary command and place
  quiz and assignment creation in a quieter paired row. Analytics sits beside
  Studio overview, where it is contextually relevant. All retain real routes.
- Recent enrollments show real student display name, course, and enrollment
  time, with loading, error, and empty states.
- The profile header is left-aligned, excludes email, and places biography
  content below a divider. Studio overview stays on the dashboard only.
- Quiz and assignment status chips are content-aware, include counts, and
  automatically select an available group.
- Payouts now show available, pending, gross, net, fees, withdrawn, and payout
  history from Supabase. Withdrawal is disabled until PayFast is configured;
  the client cannot create financial records.

## Backend contract

Migration `20261013000000_teacher_dashboard_finance.sql` adds:

- `get_teacher_dashboard_overview(integer)` for owned enrollment totals and a
  privacy-safe recent enrollment projection.
- `teacher_earning_entries` and `teacher_payouts` as provider-owned ledgers.
- `get_teacher_financial_overview(integer)` for teacher-owned financial totals
  and payout history.
- Owner-only read policies. Authenticated clients receive no insert, update, or
  delete grants on financial tables.

The financial tables intentionally start empty. A future PayFast webhook or
trusted server process must create and reconcile entries; the Flutter client
must never infer sales or manufacture payouts.

## Verification

- Hosted migration applied on 2026-10-13.
- Hosted SQL test validates aggregate accuracy, teacher-only RPC access, and
  denial of client-created payouts.
- Mapper tests cover populated and empty Supabase payloads.
- Widget tests cover empty, draft-only, published-only, and mixed assessment
  filters.
- Responsive widget tests cover a compact phone dashboard and tablet profile,
  including enrollment rendering, hidden email, responsive actions, and payout empty
  state.
