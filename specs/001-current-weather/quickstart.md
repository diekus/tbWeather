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
  "location": "London"
}
```

**Run**:
```bash
pixlet render tbweather.star location=London --gif -o output-london.gif
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

## Scenario 3 — ERROR state: unresolvable city name

Validates: FR-009, edge case (invalid location)

**Config file** (`config-bad.json`):
```json
{
  "location": "XXXINVALIDCITYYYY"
}
```

**Run**:
```bash
pixlet render tbweather.star location=XXXINVALIDCITYYYY --gif -o output-error.gif
open output-error.gif
```

**Expected outcome**:
- Applet does NOT crash
- A "No data" error message is displayed in red

---

## Scenario 4 — DEFAULT state: no location configured

Validates: FR-006 (London default), edge case (initial load)

**Config file** (`config-empty.json`):
```json
{}
```

**Run**:
```bash
pixlet render tbweather.star --gif -o output-empty.gif
open output-empty.gif
```

**Expected outcome**:
- Applet does NOT crash
- London weather is shown (default location per FR-006)

---

## Scenario 5 — Three-digit temperature (negative)

Validates: SC-003 (no overlap), edge case (negative temperatures)

Test with Helsinki (best during winter months when temperatures go sub-zero).

**Run**:
```bash
pixlet render tbweather.star location=Helsinki --gif -o output-helsinki.gif
open output-helsinki.gif
```

**Expected outcome**:
- Both actual temp (e.g., "−10°") and feels-like (e.g., "Feels: −14°") are fully
  visible without overlap or truncation

---

## Push to Physical Device

Once local render validation passes:

```bash
pixlet login
pixlet push --installation tbweather tbweather.star location=London
```

**Expected outcome**: The Tidbyt display cycles to the tbWeather applet and shows
live weather data for the configured location within a few seconds.

---

## Schema Validation

```bash
pixlet render tbweather.star location=London --gif -o /dev/null
```

**Expected outcome**: No errors; render completes successfully.

---

## References

- Data model: [data-model.md](./data-model.md)
- Applet interface contract: [contracts/applet-interface.md](./contracts/applet-interface.md)
- Feature spec: [spec.md](./spec.md)
