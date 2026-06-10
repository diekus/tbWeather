# Contract: Pixlet Applet Interface

**Applet**: tbweather
**File**: `tbweather.star`
**Framework**: Pixlet / Starlark
**Date**: 2026-06-08

---

## Overview

A Pixlet applet must expose exactly two top-level functions to be valid:
`main(config)` and `get_schema()`. This document defines the expected signatures,
inputs, outputs, and behaviour contracts for each.

---

## Function: `main(config)`

### Signature

```starlark
def main(config):
    ...
    return render.Root(...)
```

### Input

| Parameter | Type | Description |
|-----------|------|-------------|
| `config` | `config` object | Key-value store of user-configured schema values. Access via `config.get(key)` or `config.get(key, default)`. |

**Expected config keys**:

| Key | Schema Type | Required | Description |
|-----|-------------|----------|-------------|
| `"location"` | Location JSON string | Yes (graceful fallback if absent) | Serialised JSON with `lat`, `lng`, `description`, `timezone` |

### Output

Returns a `render.Root(...)` widget tree. MUST always return a valid render tree
(never `None`, never an error exception that crashes the applet).

### Behaviour Contract

1. If `config.get("location")` returns `None` or cannot be parsed → render
   UNCONFIGURED state.
2. If the Open-Meteo HTTP request fails or returns a non-200 status → render ERROR
   state. Do not raise an unhandled exception.
3. If JSON parsing of the response fails for any required field → render ERROR state.
4. Otherwise → render POPULATED state with WeatherReading data.
5. The function MUST complete within Pixlet's execution timeout (typically 5–10 s);
   the HTTP TTL cache is the primary mechanism for keeping execution fast.

---

## Function: `get_schema()`

### Signature

```starlark
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [...],
    )
```

### Output

Returns a `schema.Schema` object. MUST always return a valid schema.

### Schema Fields

| Field ID | Type | Name | Description | Required |
|----------|------|------|-------------|----------|
| `"location"` | `schema.Text` | "Location" | City name to display weather for; defaults to `"London"` | No (default `"London"` provided) |

### Example

```starlark
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id      = "location",
                name    = "Location",
                desc    = "City name to display weather for (e.g. London, Paris, Tokyo).",
                icon    = "locationDot",
                default = "London",
            ),
        ],
    )
```

**Note**: `schema.Location` does not support a `default` parameter (its UI always
defaults to Brooklyn, NY). `schema.Text` is used instead, with city-name-to-coordinates
resolution handled by Open-Meteo's geocoding API in `geocode()`.

---

## External API Dependency: Open-Meteo Geocoding

### Endpoint

```
GET https://geocoding-api.open-meteo.com/v1/search
```

### Query Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `name` | city name string from schema | City name to resolve |
| `count` | `"1"` | Return only the top result |
| `language` | `"en"` | Response language |
| `format` | `"json"` | Response format |

### Response Contract (relevant subset)

```json
{
  "results": [
    {
      "latitude": 51.50853,
      "longitude": -0.12574,
      "timezone": "Europe/London"
    }
  ]
}
```

**Caching**: `ttl_seconds = 86400` (24 hours) — city coordinates rarely change.

**Error conditions**: Non-200 or empty `results` array → `render_error()` state.

---

## External API Dependency: Open-Meteo Weather

### Endpoint

```
GET https://api.open-meteo.com/v1/forecast
```

### Query Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `latitude` | `str({lat})` from schema.Location | Decimal latitude as string; `schema.Location` may return a float or string — always coerce with `str()` |
| `longitude` | `str({lng})` from schema.Location | Decimal longitude as string; same coercion applies |
| `current` | `temperature_2m,apparent_temperature,weather_code` | Fields to return |
| `temperature_unit` | `celsius` | Unit for all temperature values |
| `timezone` | `{timezone}` from schema.Location | IANA timezone for localised time |

### Response Contract

**Status**: `200 OK` on success

**Body** (relevant subset):
```json
{
  "current": {
    "temperature_2m":       22.5,
    "apparent_temperature": 19.8,
    "weather_code":          2
  }
}
```

**Error conditions**:
- `4xx` → invalid coordinates; render ERROR state, do not retry automatically
- `5xx` → upstream failure; render last-cached data (via `ttl_seconds`) or ERROR state
- Network timeout → render last-cached data or ERROR state

### Caching

All calls MUST include `ttl_seconds = 900` to instruct the Pixlet runtime to cache
the response for 15 minutes. This satisfies SC-004 and provides offline resilience
(SC-005 / FR-009).
