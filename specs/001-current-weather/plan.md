# Implementation Plan: Current Weather Display for Tidbyt

**Branch**: `001-current-weather` | **Date**: 2026-06-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-current-weather/spec.md`

## Summary

Build a Pixlet applet (`tbweather.star`) for the Tidbyt 64 × 32 LED display that
fetches current weather from the Open-Meteo API (free, no key required) and renders
the actual temperature, feels-like temperature, condition label, and a matching
12 × 12 pixel icon in a two-column layout. Location is configured via the native
`schema.Location` picker in the Tidbyt mobile app. Data refreshes every 15 minutes
via HTTP TTL caching.

## Technical Context

**Language/Version**: Starlark (Pixlet dialect) — version determined by installed
Pixlet CLI (`pixlet version`); target compatibility is Pixlet ≥ 0.31

**Primary Dependencies**: Pixlet standard library modules — `render`, `schema`, `http`,
`json`, `math`, `encoding/base64`; Open-Meteo API (external, free, no key)

**Storage**: N/A — no persistent storage; state lives in Pixlet's HTTP TTL cache

**Testing**: `pixlet check` (schema/syntax), `pixlet render --config` (visual fixture
tests per scenario defined in quickstart.md)

**Target Platform**: Tidbyt device (64 × 32 px RGB LED matrix); local validation via
Pixlet CLI + browser/image viewer

**Project Type**: Embedded display applet (single-file Starlark)

**Performance Goals**: Render tree completion < 5 s (Pixlet execution limit); cached
data age ≤ 15 min (SC-004); all elements visible without scrolling (SC-001)

**Constraints**: 64 × 32 pixel canvas; no file I/O; all assets embedded as base64;
single `.star` file deployment; no mutable global state; no external icon CDN

**Scale/Scope**: Single-user, single-location configuration; one applet file

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I — Code Quality & Maintainability ✅

- Single `.star` file with clearly named top-level functions (`main`, `get_schema`,
  `wmo_to_condition`, `render_weather`, `render_error`, `render_unconfigured`)
- WMO code constants defined in a named dictionary `WMO_CONDITIONS`, not inline
- `pixlet check` enforced as part of every validation pass
- No dead code; no TODO stubs in shipped applet

### Principle II — Test-First & Testing Standards ✅

- Five named validation scenarios in `quickstart.md` MUST be exercised before merge:
  populated, all-conditions, error, unconfigured, negative temperature
- All three render states (POPULATED, ERROR, UNCONFIGURED) have explicit test fixtures
- WMO → condition mapping function testable as a pure function with known inputs
- Coverage for all 7 required icon categories (SC-002 = 100%)

### Principle III — User Experience Consistency ✅

- All three display states implemented and tested (UNCONFIGURED → ERROR → POPULATED)
- Condition labels centralised in `CONDITION_LABELS` dictionary (no hard-coded strings)
- Layout fits 64 × 32 with no truncation of temperature or condition at any valid value
- Long condition labels use `render.Marquee` as fallback to prevent overflow

### Principle IV — Performance Requirements ✅

- `ttl_seconds = 900` ensures data ≤ 15 min old under normal network (SC-004)
- Last-cached data renders immediately while background refresh occurs (SC-005 / FR-009)
- No blocking computation in render path; WMO lookup is O(1) dictionary access
- Icon data embedded as base64 — no network round-trip for assets

**Constitution Check result**: All four principles satisfied. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/001-current-weather/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── applet-interface.md
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
tbweather.star           # Single Pixlet applet file
```

**Structure Decision**: Pixlet applets are single-file by convention. All logic,
constants, and base64 icon data are contained in `tbweather.star` at the repository
root. No `src/` or `tests/` directories — validation is done via `pixlet render`
fixture runs as described in `quickstart.md`.

## Implementation Notes

### Applet Structure

```
tbweather.star
├── load() declarations (render, schema, http, json, math, encoding/base64)
├── ICONS            — dict: condition_key → base64 PNG (12×12 px)
├── CONDITION_LABELS — dict: condition_key → display string
├── WMO_CONDITIONS   — dict: wmo_int → condition_key
├── wmo_to_condition(code) → condition_key
├── get_schema()     → schema.Schema with schema.Location field
├── render_unconfigured()  → render.Root (prompt text)
├── render_error()         → render.Root (error text)
├── render_weather(reading) → render.Root (two-column layout)
└── main(config)     → dispatches to one of the three render functions
```

### Layout Details (64 × 32 canvas)

```
┌──────────────────────────────────────────────────────────────────┐ 32 px
│ [icon 12×12]  │  22°C              (font: 6x13, white)           │
│               │  Partly Cloudy     (font: tb-8, light grey)      │
│               │  Feels: 20°        (font: tb-8, dim grey)        │
└──────────────────────────────────────────────────────────────────┘ 64 px
  16 px wide       48 px wide
```

Icon column is vertically centred. Right column uses `render.Column` with three
`render.Text` children. If condition label exceeds 12 characters, wrap in
`render.Marquee` (width=48, scroll_direction="horizontal").

### Key Constants

| Name | Value | Purpose |
|------|-------|---------|
| `CACHE_TTL` | `900` | HTTP cache TTL in seconds (15 min) |
| `API_URL` | `"https://api.open-meteo.com/v1/forecast"` | Weather endpoint |
| `ICON_SIZE` | `12` | Icon width and height in pixels |
| `DISPLAY_W` | `64` | Canvas width |
| `DISPLAY_H` | `32` | Canvas height |

## Complexity Tracking

> No constitution violations — this table is not required.
