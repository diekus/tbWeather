# Quickstart Validation Guide: tbWeather

**Branch**: `001-current-weather` | **Date**: 2026-06-08

This guide describes how to set up a local development environment for tbWeather
and run each validation scenario to confirm the applet works correctly before
pushing to a physical Tidbyt device.

---

## Prerequisites

1. **Install Pixlet CLI**

   Follow the official installation guide at https://tidbyt.dev/docs/build/installing-pixlet.
   Verify with:
   ```bash
   pixlet version
   ```

2. **Internet access** — the applet fetches live weather data from Open-Meteo.

3. **A Tidbyt device** (optional for local validation; required for physical testing).

---

## Scenario 1 — POPULATED state: valid location

Validates: US1 (temperature + condition display), US2 (feels-like), FR-001 through FR-010

**Config file** (`config-london.json`):
```json
{
  "location": "{\"lat\":\"51.5074\",\"lng\":\"-0.1278\",\"description\":\"London, England\",\"timezone\":\"Europe/London\"}"
}
```

**Run**:
```bash
pixlet render tbweather.star --config config-london.json --gif output-london.gif
open output-london.gif
```

**Expected outcome**:
- Current temperature shown in large text (°C)
- A condition label visible (e.g., "Partly Cloudy")
- A matching weather icon displayed to the left of the temperature
- "Feels like X°" shown as a secondary line
- All text fits within the 64 × 32 frame with no truncation of temperature or condition

---

## Scenario 2 — All condition icons: 7 condition categories

Validates: FR-003, FR-005, SC-002

Run a render for each condition by temporarily overriding the WMO code in a test
fixture (or by running at times/locations with known conditions). Confirm the correct
icon appears for each category:

| Condition | WMO code to test with | Expected icon |
|-----------|----------------------|---------------|
| Clear | 0 | Sun |
| Partly Cloudy | 2 | Sun + cloud |
| Overcast | 3 | Full cloud |
| Rain | 63 | Cloud + drops |
| Thunderstorm | 95 | Cloud + bolt |
| Snow | 73 | Cloud + snowflake |
| Fog | 45 | Fog lines |

---

## Scenario 3 — ERROR state: bad coordinates

Validates: FR-009, edge case (invalid location)

**Config file** (`config-bad.json`):
```json
{
  "location": "{\"lat\":\"999\",\"lng\":\"999\",\"description\":\"Invalid\",\"timezone\":\"UTC\"}"
}
```

**Run**:
```bash
pixlet render tbweather.star --config config-bad.json --gif output-error.gif
open output-error.gif
```

**Expected outcome**:
- Applet does NOT crash
- An error or "No data" message is displayed

---

## Scenario 4 — UNCONFIGURED state: no location

Validates: Edge case (initial load), Constitution UX principle

**Config file** (`config-empty.json`):
```json
{}
```

**Run**:
```bash
pixlet render tbweather.star --config config-empty.json --gif output-empty.gif
open output-empty.gif
```

**Expected outcome**:
- Applet does NOT crash
- A prompt message (e.g., "Set location in app") is displayed

---

## Scenario 5 — Three-digit temperature (negative)

Validates: SC-003 (no overlap), edge case (negative temperatures)

Test with a location that returns sub-zero temperatures (e.g., Helsinki in January)
or mock the value with a test config fixture that overrides the API response.

**Expected outcome**:
- Both actual temp (e.g., "−10°") and feels-like (e.g., "Feels: −14°") are fully
  visible without overlap or truncation

---

## Push to Physical Device

Once local render validation passes:

```bash
pixlet login
pixlet push --installation tbweather tbweather.star --config config-london.json
```

**Expected outcome**: The Tidbyt display cycles to the tbWeather applet and shows
live weather data for the configured location within a few seconds.

---

## Schema Validation

```bash
pixlet check tbweather.star
```

**Expected outcome**: No errors reported; schema fields validated.

---

## References

- Data model: [data-model.md](./data-model.md)
- Applet interface contract: [contracts/applet-interface.md](./contracts/applet-interface.md)
- Feature spec: [spec.md](./spec.md)
