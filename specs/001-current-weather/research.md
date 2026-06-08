# Research: Current Weather Display for Tidbyt

**Branch**: `001-current-weather` | **Date**: 2026-06-08

## Decision Log

---

### 1. Runtime & Language

**Decision**: Starlark via the Pixlet framework

**Rationale**: Tidbyt devices exclusively run Pixlet applets. Starlark is a sandboxed,
Python-like language. No alternative exists for native Tidbyt deployment.

**Key constraints inherited**:
- No mutable global state; all logic runs in `main(config)` per render cycle
- No file I/O — all assets must be embedded as base64 strings in the `.star` file
- Standard library includes `render`, `schema`, `http`, `cache`, `math`, `re`, `json`,
  `time`, and `encoding/base64`

**Alternatives considered**: None — platform-mandated.

---

### 2. Weather Data Source

**Decision**: Open-Meteo API (`api.open-meteo.com`)

**Rationale**:
- Completely free with no API key required — zero configuration friction for users
- Returns WMO-standard weather codes that map cleanly to display condition categories
- Provides `temperature_2m` (actual) and `apparent_temperature` (feels-like) in a
  single `current` endpoint call
- Supports `temperature_unit=celsius` natively, matching FR-007
- Returns JSON directly parseable with Starlark's `json.decode()`

**API endpoint**:
```
GET https://api.open-meteo.com/v1/forecast
  ?latitude={lat}
  &longitude={lon}
  &current=temperature_2m,apparent_temperature,weather_code
  &temperature_unit=celsius
  &timezone=auto
```

**Response shape** (relevant fields only):
```json
{
  "current": {
    "temperature_2m": 22.5,
    "apparent_temperature": 20.1,
    "weather_code": 3
  }
}
```

**Alternatives considered**:
- *OpenWeatherMap*: Requires API key registration → rejected (user friction)
- *WeatherAPI*: Free tier available but requires API key → rejected
- *wttr.in*: Text-oriented, unreliable JSON format → rejected

---

### 3. Caching Strategy

**Decision**: HTTP-level TTL caching via Pixlet's built-in `ttl_seconds`

**Rationale**: Pixlet's `http.get()` accepts a `ttl_seconds` parameter that caches
responses automatically in the Tidbyt cloud. Setting `ttl_seconds = 900` (15 minutes)
satisfies SC-004 (data ≤ 15 min old) without any manual cache management.

The device continues to render from the last successfully cached response if the
network is unavailable, satisfying FR-009 and SC-005.

**Configuration**: `ttl_seconds = 900`

**Alternatives considered**:
- *Manual `cache.get()`/`cache.set()`*: More control but adds complexity; not needed
  for this use case.

---

### 4. Location Configuration

**Decision**: `schema.Text` field with city name + Open-Meteo geocoding API

**Rationale**: `schema.Location` does not support a `default` parameter — its UI
always shows Brooklyn, NY as the initial value regardless of app code. Switching to
`schema.Text(default="London")` gives the config page the correct default while
keeping UX simple (users type a city name). City-name-to-coordinates resolution uses
Open-Meteo's free geocoding API (`geocoding-api.open-meteo.com`), which requires no
API key and is cached for 24 hours.

**Geocoding endpoint**:
```
GET https://geocoding-api.open-meteo.com/v1/search?name={city}&count=1&language=en&format=json
```

Returns `latitude`, `longitude`, and `timezone` for the top matching city.

**Default value**: `DEFAULT_LOCATION = "London"` constant in the applet; the config
field is pre-filled and the app displays London weather with no user setup required.

**Alternatives considered**:
- *`schema.Location` with default*: Does not support `default` parameter in current
  Pixlet version → rejected
- *Manual lat/lon text fields*: Poor UX for most users → rejected

---

### 5. Condition Icon Approach

**Decision**: Base64-encoded PNG pixel art embedded in the `.star` file

**Rationale**: Pixlet applets cannot read files from disk at runtime; all assets must
be embedded. The standard community pattern (confirmed in the AccuWeather applet) is
to embed icon data as base64 strings in a Starlark dictionary keyed by condition
category. Icons are rendered via `render.Image(src=base64.decode(ICON_DATA[condition]))`.

**Icon size**: 12 × 12 pixels to leave adequate room for text on the 64 × 32 display.

**Icon set** (one per category):
| Category | Icon description |
|----------|-----------------|
| clear | Yellow sun circle |
| partly_cloudy | Sun with partial cloud overlay |
| overcast | Solid grey cloud |
| rain | Blue cloud with droplets |
| thunderstorm | Dark cloud with lightning bolt |
| snow | White cloud with snowflake/dots |
| fog | Horizontal grey lines |
| unknown | Question mark or blank |

**Alternatives considered**:
- *Animated GIFs per condition*: Adds visual richness but significantly increases
  file size and complexity for a v1 → deferred to a future enhancement
- *Fetching icons from a CDN*: Adds network dependency and latency on every render

---

### 6. Display Layout

**Decision**: Two-column layout — icon left, text stack right

**Rationale**: The 64 × 32 pixel canvas is extremely constrained. A two-column
approach dedicates 16 px (width) to the icon and 48 px to text content, which
accommodates up to a 4-character temperature string (e.g., "−10°") plus condition
label and feels-like line using the available Pixlet fonts.

**Font decisions**:
| Element | Font | Approx height |
|---------|------|---------------|
| Temperature (primary) | `"6x13"` | 13 px |
| Condition label | `"tb-8"` | 8 px |
| Feels-like | `"tb-8"` | 8 px |

Total right-column height: 13 + 8 + 8 = 29 px, comfortably within 32 px.

**Colour scheme**:
- Temperature: White `"#FFFFFF"` on dark background
- Condition label: Light grey `"#AAAAAA"`
- Feels-like label: Dimmer grey `"#888888"`
- Background: Black `"#000000"` (Tidbyt default)

**Alternatives considered**:
- *Top-bottom split*: Large temperature top row, details bottom → less room for icon
- *Marquee scrolling*: Useful for long condition strings → retained as fallback for
  labels exceeding ~8 characters

---

### 7. Error & Loading States (Constitution Principle III)

**Decision**: Explicit fallback render tree for error conditions

**Rationale**: Per the constitution's UX Consistency principle, all three states
(loading, error, populated) MUST be handled. Since Pixlet renders on demand (no
"loading" state between calls), the two states to handle explicitly are:

- **No data yet / empty config**: Render a placeholder with location prompt text
- **API error / cache miss**: Render a static error icon with "No data" text
- **Successful data**: Normal render tree

These are implemented as conditional branches at the top of `main()`.

---

### 8. Testing Approach

**Decision**: `pixlet render` for visual validation + structured sample data for
unit-level logic testing

**Rationale**: Starlark has no native unit-test runner. The standard Pixlet testing
pattern is:
1. Use `pixlet check tbweather.star` to validate syntax and schema
2. Use `pixlet render tbweather.star` with a `--config` file to test specific scenarios
3. Create a set of named config fixtures (one per condition category) to cover SC-002

For logic functions (temperature rounding, WMO code mapping), the functions can be
called directly in a test harness `.star` file that prints assertion results.

---

## Resolved Clarifications

| Item | Resolution |
|------|-----------|
| Temperature unit | Celsius only (user decision, 2026-06-08) |
| Weather API | Open-Meteo (free, no key) |
| Location input | schema.Text + Open-Meteo geocoding (schema.Location lacks default support) |
| Icon format | Base64 PNG embedded in applet |
| Refresh interval | 15 minutes (900 s TTL) |
| Layout | Two-column: icon left, text right |
