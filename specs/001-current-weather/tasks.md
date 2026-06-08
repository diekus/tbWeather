---
description: "Task list for tbWeather — Current Weather Display for Tidbyt"
---

# Tasks: Current Weather Display for Tidbyt

**Input**: Design documents from `specs/001-current-weather/`

**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Guidance**: Tasks are intentionally small — each is a single reviewable unit (one function,
one data structure, one validation scenario). No task should exceed ~40 lines of code change.

**Tests**: Validation tasks use `pixlet render --config` fixtures as defined in `quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and
testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (no dependency on other in-progress tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- All tasks target `tbweather.star` at the repo root unless noted otherwise

---

## Phase 1: Setup

**Purpose**: Bootstrap a valid, runnable Pixlet applet skeleton.

- [x] T001 Create `tbweather.star` with `load()` declarations for `render`, `schema`, `http`,
  `json`, and `encoding/base64`; add stub `main(config)` and stub `get_schema()`
- [ ] T002 Run `pixlet check tbweather.star` and confirm zero errors on the skeleton
  *(requires pixlet CLI — install from https://tidbyt.dev/docs/build/installing-pixlet)*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared constants, data structures, and helper functions that all user
stories depend on. MUST be complete before any user story work begins.

**⚠️ CRITICAL**: No user story implementation can start until Phase 2 is complete.

- [x] T003 Add constants block to `tbweather.star`: `CACHE_TTL = 900`, `API_URL`,
  `ICON_SIZE = 12`, `DISPLAY_W = 64`, `DISPLAY_H = 32`
- [x] T004 Add `WMO_CONDITIONS` dict to `tbweather.star` mapping all WMO integer codes
  to canonical condition keys (see data-model.md § Condition Mapping — all 14 code groups)
- [x] T005 Add `CONDITION_LABELS` dict to `tbweather.star` mapping each condition key
  to its display string (e.g., `"clear": "Clear"`, `"partly_cloudy": "Partly Cloudy"`)
- [x] T006 Add `wmo_to_condition(code)` function to `tbweather.star` — looks up `code`
  in `WMO_CONDITIONS`; returns `"unknown"` for any unmapped code
- [x] T007 Implement `get_schema()` in `tbweather.star` — `schema.Schema` with one
  `schema.Location(id="location", ...)` field (see contracts/applet-interface.md § get_schema)
- [x] T008 Implement `render_unconfigured()` in `tbweather.star` — returns a
  `render.Root` displaying "Set location in app" centred on the canvas
- [x] T009 Implement `render_error()` in `tbweather.star` — returns a `render.Root`
  displaying "No data" in red; no crash on any input
- [x] T010 Implement `main(config)` initial dispatch in `tbweather.star` — parse
  `config.get("location")`; if absent or unparseable → call `render_unconfigured()`

**Checkpoint**: `pixlet check tbweather.star` passes; `pixlet render` with empty config
shows "Set location in app".

---

## Phase 3: User Story 1 — View Current Weather at a Glance (Priority: P1) 🎯 MVP

**Goal**: Display current temperature, condition label, and matching icon on the Tidbyt.

**Independent Test**: `pixlet render tbweather.star --config config-london.json` produces
a 64×32 frame showing a large temperature (°C), a condition label, and a matching icon.
See quickstart.md Scenario 1.

### Implementation for User Story 1

- [x] T011 [US1] Add `ICON_DATA` dict and `ICON_KEY` dict to `tbweather.star` — 8 base64-encoded
  12×12 px PNGs (clear, partly_cloudy, overcast, rain, thunderstorm, snow, fog, unknown)
  plus `_icon_for(condition)` helper; icons generated via Python PNG encoder
- [x] T012 [US1] Implement `fetch_weather(lat, lng, timezone)` in `tbweather.star` —
  calls `http.get(API_URL, params={...}, ttl_seconds=CACHE_TTL)`; returns body string or
  `None` on non-200 status
- [x] T013 [US1] Implement `parse_weather_response(body)` in `tbweather.star` —
  decodes JSON, extracts `temperature_2m`, `apparent_temperature`, `weather_code`,
  derives `condition` and `condition_label`; returns dict or `None` on missing fields
- [x] T014 [US1] Implement `render_weather(reading)` in `tbweather.star` — Column layout:
  Row 1 (icon 12px + temp "6x13"), Row 2 (condition Marquee), Row 3 (feels-like "tb-8")
- [x] T015 [US1] Wire full dispatch in `main(config)` in `tbweather.star` —
  parse location JSON → `fetch_weather` → `render_error()` if None →
  `parse_weather_response` → `render_error()` if None → `render_weather()`
- [x] T016 [US1] Create `config-london.json` fixture at repo root
  (London lat=51.5074, lng=-0.1278, timezone=Europe/London)
- [ ] T017 [US1] Run `pixlet render tbweather.star --config config-london.json
  --gif output-london.gif` and visually verify: large temp, condition label, correct
  icon *(requires pixlet CLI)*
- [ ] T018 [P] [US1] Run `pixlet render` for each of the 7 required condition categories
  using test configs with known WMO codes; verify correct icon for each condition
  (quickstart.md Scenario 2) *(requires pixlet CLI)*

**Checkpoint**: User Story 1 fully functional — temperature + condition + icon visible;
all 7 icon categories verified (SC-002 = 100%).

---

## Phase 4: User Story 2 — View Feels-Like Temperature (Priority: P2)

**Goal**: Add a secondary feels-like temperature line to the existing layout.

**Independent Test**: `pixlet render` output shows "Feels X°" below the condition
label with no overlap, including for three-digit negative values.

### Implementation for User Story 2

- [x] T019 [US2] `render_weather(reading)` in `tbweather.star` includes feels-like as
  third row: `"Feels %d°"` in `"tb-8"` font (dim grey `"#888888"`) — already implemented
  together with T014; three text lines fit in 32 px height
- [x] T020 [US2] Create `config-negative.json` fixture at repo root
  (Helsinki lat=60.1699, lng=24.9384, timezone=Europe/Helsinki — use in winter)
- [ ] T021 [US2] Run `pixlet render tbweather.star --config config-negative.json
  --gif output-negative.gif` and visually confirm both values show without overlap
  (quickstart.md Scenario 5) *(requires pixlet CLI; best run when Helsinki temp is sub-zero)*

**Checkpoint**: User Stories 1 AND 2 independently functional — feels-like visible
alongside actual temp with no layout issues.

---

## Phase 5: User Story 3 — Automatic Data Refresh (Priority: P3)

**Goal**: Confirm cache TTL is active and the app degrades gracefully when the network
is unavailable.

**Independent Test**: App renders last-known data rather than crashing when the API
is unreachable. Refresh cycle governed by `ttl_seconds = 900`.

### Implementation for User Story 3

- [x] T022 [US3] `fetch_weather()` in `tbweather.star` uses `ttl_seconds=CACHE_TTL`
  (CACHE_TTL = 900) — confirmed present in implementation
- [x] T023 [US3] Create `config-bad.json` fixture at repo root
  (invalid coordinates lat=999, lng=999 to trigger API error)
- [ ] T024 [US3] Run `pixlet render tbweather.star --config config-bad.json
  --gif output-error.gif` and confirm ERROR state renders cleanly
  (quickstart.md Scenario 3) *(requires pixlet CLI)*
- [ ] T025 [US3] Run `pixlet render tbweather.star --config config-empty.json
  --gif output-empty.gif` and confirm UNCONFIGURED state renders
  (quickstart.md Scenario 4) *(requires pixlet CLI)*

**Checkpoint**: All three user stories independently functional; app degrades cleanly
on network errors and missing config.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: UX hardening and final validation pass across all stories.

- [x] T026 `render_weather()` in `tbweather.star` uses `render.Marquee` for all condition
  labels (scrolls automatically only when label exceeds display width); `width=64, delay=80`
- [ ] T027 [P] Run `pixlet check tbweather.star` — confirm zero errors or warnings
  *(requires pixlet CLI)*
- [ ] T028 Run the complete quickstart.md validation suite (all 5 scenarios) sequentially
  and confirm every scenario passes *(requires pixlet CLI)*
- [x] T029 [P] `specs/001-current-weather/checklists/requirements.md` — all 16 items
  pass; spec checklist is 100% complete
- [ ] T030 Push to Tidbyt device: `pixlet push --installation tbweather tbweather.star
  --config config-london.json`; visually verify live weather data on the physical display
  *(requires pixlet CLI + physical Tidbyt device)*

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 completion — first deliverable / MVP
- **US2 (Phase 4)**: Depends on Phase 3 completion (extends `render_weather`)
- **US3 (Phase 5)**: Depends on Phase 2 completion — can overlap with Phase 4 for
  the validation tasks only (T022 is a code review, not a new feature)
- **Polish (Phase 6)**: Depends on all user story phases complete

### Within Each Phase

- Tasks with `[P]` can start as soon as their phase begins
- No `[P]` = depends on previous task completing first within the phase
- Validation tasks (render + visual check) MUST run after the code task they verify

---

## Parallel Opportunities

### User Story 1 — parallelisable after T010

```text
T011: Add ICONS dict          ─┐
T012: fetch_weather()          ├─ all independent, can run in parallel
T013: parse_weather_response() ┘

T014: render_weather()         — depends on T011 (needs ICONS), T013 (needs reading shape)
T015: wire main()              — depends on T012, T013, T014
```

### Polish (Phase 6)

```text
T027: pixlet check  ─┐
T029: checklist     ─┴─ independent, can run in parallel with T026/T028
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (T001–T002)
2. Complete Phase 2 (T003–T010)
3. Complete Phase 3 (T011–T018)
4. **STOP and VALIDATE**: Run quickstart.md Scenario 1 and Scenario 2
5. Push MVP to device and confirm live display

### Incremental Delivery

1. Phase 1 + 2 → Skeleton validated ✓
2. Phase 3 → MVP: temp + condition + icon ✓
3. Phase 4 → Add feels-like ✓
4. Phase 5 → Confirm refresh/offline ✓
5. Phase 6 → Polish + full validation + device deploy ✓

---

## Notes

- `[P]` = different concern or data, no file conflict, safe to run concurrently
- `[Story]` label maps to spec.md user stories for traceability
- Each phase ends with a named checkpoint — stop and validate before proceeding
- Validation tasks (T002, T017, T018, T021, T024, T025, T027, T028, T030) all require
  the Pixlet CLI — install from https://tidbyt.dev/docs/build/installing-pixlet
- T021 (negative temperature test) is best run when Helsinki is actually cold (winter)
- Commit after each task or logical group; keep commits small and reviewable
