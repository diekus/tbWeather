<!--
SYNC IMPACT REPORT
==================
Version change: [TEMPLATE] → 1.0.0
New constitution — initial ratification.

Principles added:
  I.  Code Quality & Maintainability (new)
  II. Test-First & Testing Standards (new)
  III. User Experience Consistency (new)
  IV. Performance Requirements (new)

Sections added:
  - Core Principles (4 principles)
  - Quality Gates
  - Development Workflow
  - Governance

Templates reviewed:
  ✅ .specify/templates/plan-template.md — Constitution Check gate aligns with all four principles
  ✅ .specify/templates/spec-template.md — Success Criteria and Functional Requirements align with UX and performance principles
  ✅ .specify/templates/tasks-template.md — Phase structure supports test-first and Polish phase covers performance/UX hardening

Deferred TODOs:
  None — all placeholders resolved.
-->

# tbWeather Constitution

## Core Principles

### I. Code Quality & Maintainability

Every piece of code merged into the project MUST meet a consistent quality bar that
makes the codebase legible, safe, and changeable by any contributor.

- All code MUST pass static analysis and linting with zero warnings before merging.
- Functions and modules MUST have a single, clearly named responsibility; side-effects
  MUST be explicit and isolated.
- Magic numbers and non-obvious constants MUST be named and placed in a shared
  constants module.
- Dead code, commented-out blocks, and TODO stubs older than one sprint MUST be
  removed before merge; open work MUST live in issues, not inline.
- Dependency upgrades MUST be intentional and documented; unused dependencies MUST
  be removed.
- All public interfaces MUST include type annotations (or equivalent for the target
  language); unannotated public APIs MUST NOT be merged.

**Rationale**: Readable, consistent code reduces onboarding time, minimises
defect density, and ensures AI-assisted tooling (linters, agents) can reason about
the codebase reliably.

### II. Test-First & Testing Standards (NON-NEGOTIABLE)

Automated testing is a first-class deliverable, not an afterthought. Tests MUST be
written before implementation code is considered complete.

- The Red-Green-Refactor cycle is MANDATORY: tests MUST be authored and confirmed
  failing before the corresponding implementation is written.
- Every user story MUST have at least one integration or end-to-end test that
  exercises the full path from input to observable output.
- Unit test coverage for business-logic modules MUST reach 80% line coverage at
  minimum; critical weather-data parsing and calculation modules MUST reach 90%.
- Tests MUST be deterministic: no flakiness tolerance. A flaky test MUST be fixed or
  deleted within one sprint of identification.
- External API calls (weather data providers) MUST be stubbed/mocked in unit and
  integration tests to prevent network-dependent test suites.
- Acceptance scenarios defined in `spec.md` MUST map 1-to-1 to automated test cases;
  untested acceptance scenarios MUST be flagged as spec gaps before the feature ships.

**Rationale**: Weather apps depend heavily on parsing external data formats and
handling edge-case conditions (missing fields, units, timezones). A disciplined
test suite catches regressions before users see them.

### III. User Experience Consistency

The UI and interactions across all surfaces of tbWeather MUST feel cohesive, fast,
and predictable regardless of which feature or screen the user is on.

- A shared design token system (colours, typography, spacing, iconography) MUST be
  defined and used in all UI components; ad-hoc style values MUST NOT be introduced.
- Every screen MUST have an explicit loading state, an error/empty state, and a
  populated state — all three MUST be implemented and tested before a screen ships.
- User-facing copy (labels, error messages, units of measure) MUST be centralised
  in a single localisation or strings file; hard-coded strings in view code MUST
  NOT be merged.
- Interactive controls MUST meet WCAG 2.1 AA contrast and tap-target size guidelines
  (minimum 44 × 44 pt / dp).
- Navigation and transition patterns MUST be consistent: the same user action MUST
  always produce the same type of navigation response throughout the app.
- Breaking changes to UI flows visible to end users MUST be accompanied by an
  updated user story acceptance scenario before merging.

**Rationale**: Weather apps are used in quick, high-context moments (checking before
leaving the house). Inconsistent UX adds cognitive load at exactly the wrong time and
erodes trust in the data being displayed.

### IV. Performance Requirements

tbWeather MUST remain responsive under real-world conditions, including slow networks
and low-end devices.

- App launch to first meaningful weather data render MUST complete in under 2 seconds
  on a mid-range device with a warm cache; cold-start with network fetch MUST complete
  in under 4 seconds.
- UI frames MUST render at 60 fps during scroll and transition animations; jank (frame
  drops below 30 fps) MUST be treated as a P1 bug.
- Network payloads from weather APIs MUST be cached locally with an appropriate TTL
  (default: 10 minutes); the app MUST render stale cached data immediately while
  refreshing in the background rather than blocking the user on network latency.
- Memory usage MUST NOT grow unboundedly across navigation events; instruments/profiler
  runs MUST be part of the definition-of-done for any feature that introduces new
  data-fetching or image-rendering code.
- Background refresh and location tasks MUST complete within platform-imposed budget
  limits; overruns MUST be caught in CI via timeout assertions.

**Rationale**: Performance is a feature. Slow weather apps get deleted. Caching
discipline also reduces API costs and supports offline-first use cases.

## Quality Gates

These gates MUST be satisfied before any feature branch is merged to `main`:

1. **Linting / Static Analysis** — zero warnings, enforced by CI.
2. **Test Suite** — all tests green; coverage thresholds enforced (see Principle II).
3. **Constitution Check** — plan.md's Constitution Check section MUST confirm no
   violations of Principles I–IV, or document a justified exception.
4. **UX Review** — all three screen states (loading / error / data) verified in a
   device build or simulator.
5. **Performance Baseline** — launch time and frame-rate assertions pass in CI for
   features touching data-fetching or rendering.

## Development Workflow

- Features MUST be developed on numbered branches following the project's sequential
  naming convention (`###-feature-name`).
- Each task in `tasks.md` MUST be committed individually or in logical groups; large
  unreviewed commits are prohibited.
- All PRs MUST reference the spec and plan docs for the feature under review.
- The `main` branch MUST always be in a releasable state; hotfixes follow the same
  quality-gate process as features (no bypassing CI).

## Governance

This constitution supersedes all prior ad-hoc conventions. Amendments require:

1. A written proposal describing the change and its rationale.
2. Agreement from the project owner.
3. A version bump applied according to the semantic versioning policy below:
   - **MAJOR**: Removal or redefinition of a principle; backward-incompatible
     governance change.
   - **MINOR**: New principle, section, or materially expanded guidance added.
   - **PATCH**: Clarifications, wording, or typo fixes.
4. An updated Sync Impact Report prepended to this file.
5. Corresponding updates to affected templates before the amendment is ratified.

All PRs and code reviews MUST verify compliance with the four core principles.
Complexity violations MUST be justified in the plan's Complexity Tracking table
before being accepted.

**Version**: 1.0.0 | **Ratified**: 2026-06-08 | **Last Amended**: 2026-06-08
