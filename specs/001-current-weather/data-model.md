# Data Model: Current Weather Display for Tidbyt

**Branch**: `001-current-weather` | **Date**: 2026-06-08

## Overview

The applet has no persistent storage. All data flows from the Open-Meteo API
response through in-memory Starlark variables to the render tree within a single
`main(config)` call. The entities below describe the logical structure of that data.

---

## Entities

### WeatherReading

The parsed snapshot of current weather at the configured location.

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `temp_c` | int | API `current.temperature_2m` (rounded) | Actual temperature in °C |
| `feels_like_c` | int | API `current.apparent_temperature` (rounded) | Apparent/feels-like temperature in °C |
| `wmo_code` | int | API `current.weather_code` | WMO weather interpretation code |
| `condition` | string | Derived via `wmo_to_condition(wmo_code)` | Normalised condition category key |
| `condition_label` | string | Derived via `CONDITION_LABELS[condition]` | Human-readable label (e.g., "Partly Cloudy") |

**Validation rules**:
- `temp_c` and `feels_like_c` MUST be integers (rounded from float); valid range −60 to +60
- `wmo_code` MUST be a non-negative integer; unmapped codes fall back to `"unknown"`
- `condition` MUST be one of the canonical keys listed in the Condition Mapping table below

---

### Location

The user-configured target location, deserialized from the `schema.Location` JSON value.

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `lat` | string | `config.get("location")` → JSON `lat` | Latitude as decimal string |
| `lng` | string | `config.get("location")` → JSON `lng` | Longitude as decimal string |
| `description` | string | JSON `description` | Human-readable place name (not displayed in v1) |
| `timezone` | string | JSON `timezone` | IANA timezone identifier (passed to API as `timezone`) |

**Validation rules**:
- If `config.get("location")` returns `None` or fails to parse, the applet MUST
  render the unconfigured state (see State Transitions below)
- `lat` and `lng` are passed directly as query parameters; no client-side range
  validation required (API rejects invalid coordinates)

---

### ConditionIcon

Maps a condition category key to its base64-encoded PNG pixel art.

| Field | Type | Description |
|-------|------|-------------|
| `key` | string | Canonical condition key (see mapping below) |
| `data` | string | Base64-encoded 12 × 12 pixel PNG image data |

Stored as a Starlark dictionary constant `ICONS` keyed by condition key.
If a key is missing, the `"unknown"` entry is used as fallback.

---

## Condition Mapping

Maps WMO weather interpretation codes to canonical condition categories.

| WMO Code(s) | Canonical Key | Display Label |
|-------------|---------------|---------------|
| 0 | `"clear"` | "Clear" |
| 1 | `"mainly_clear"` | "Mainly Clear" |
| 2 | `"partly_cloudy"` | "Partly Cloudy" |
| 3 | `"overcast"` | "Overcast" |
| 45, 48 | `"fog"` | "Fog" |
| 51, 53, 55 | `"drizzle"` | "Drizzle" |
| 56, 57 | `"freezing_drizzle"` | "Freezing Drizzle" |
| 61, 63, 65 | `"rain"` | "Rain" |
| 66, 67 | `"freezing_rain"` | "Freezing Rain" |
| 71, 73, 75, 77 | `"snow"` | "Snow" |
| 80, 81, 82 | `"rain_showers"` | "Showers" |
| 85, 86 | `"snow_showers"` | "Snow Showers" |
| 95 | `"thunderstorm"` | "Thunderstorm" |
| 96, 99 | `"heavy_thunderstorm"` | "Thunderstorm" |
| *(unrecognised)* | `"unknown"` | "N/A" |

**Icon grouping** (multiple condition keys share the same icon asset):
- `"clear"` + `"mainly_clear"` → sun icon
- `"partly_cloudy"` → partly cloudy icon
- `"overcast"` → overcast cloud icon
- `"fog"` → fog icon
- `"drizzle"` + `"freezing_drizzle"` + `"rain"` + `"freezing_rain"` + `"rain_showers"` → rain icon
- `"snow"` + `"snow_showers"` → snow icon
- `"thunderstorm"` + `"heavy_thunderstorm"` → thunderstorm icon
- `"unknown"` → blank / question mark icon

---

## State Transitions

The applet has three explicit render states. `main()` evaluates them in order:

```
1. UNCONFIGURED
   Trigger: config.get("location") is None or empty
   Render:  Prompt text "Set location in app"
   Next:    → LOADING (after user configures location)

2. ERROR
   Trigger: http.get() fails (non-200 status) OR JSON parse fails
   Render:  Error icon + "No data" text
   Next:    → LOADING (on next render cycle, cache retried)

3. POPULATED
   Trigger: Valid WeatherReading parsed from API response
   Render:  Two-column layout (icon + temperature + condition + feels-like)
   Next:    Remains POPULATED; refreshes via ttl_seconds cache expiry
```

---

## API Response Contract (Inbound)

The applet depends on the Open-Meteo `/v1/forecast` endpoint. The relevant subset
of the response schema is:

```json
{
  "current": {
    "temperature_2m":       <number>,
    "apparent_temperature": <number>,
    "weather_code":         <integer>
  }
}
```

All three fields MUST be present for the applet to enter the POPULATED state.
If any field is missing, the applet falls back to the ERROR state.
