# Feature Specification: Current Weather Display for Tidbyt

**Feature Branch**: `001-current-weather`

**Created**: 2026-06-08

**Status**: Draft

**Input**: User description: "Build an application that shows the current weather for a specified location. This app is meant to run in a tidbyt device, and shows the current temperature, feels like temperature, weather condition, and a small icon or animation in the screen associated to the condition (sunny, partially cloudy, snow, etc). It focuses the current temperature and weather condition."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Current Weather at a Glance (Priority: P1)

A user walks past their Tidbyt device and immediately reads the current temperature and
weather condition for their configured location without any interaction. The display
cycles or remains static showing the key data prominently.

**Why this priority**: This is the core value of the app — instant, ambient weather
awareness from across the room. Without this, the app has no purpose.

**Independent Test**: Configure the app with a valid location. The Tidbyt display should
show the current temperature (large, dominant text), weather condition label, and a
matching visual icon within a few seconds of the device loading the app.

**Acceptance Scenarios**:

1. **Given** the app is installed on a Tidbyt device with a valid location configured,
   **When** the device displays the app,
   **Then** the current temperature is shown in large, prominent text and a weather
   condition label is visible (e.g., "Sunny", "Cloudy", "Rain").

2. **Given** the app is displayed on the device,
   **When** the user views the screen,
   **Then** a visual icon or animation matching the current condition is shown alongside
   the temperature and condition text.

3. **Given** the weather data has been fetched,
   **When** the condition is any of: clear/sunny, partly cloudy, overcast, rain,
   thunderstorm, snow, fog,
   **Then** the corresponding distinct icon or animation is displayed for that condition.

---

### User Story 2 - View Feels-Like Temperature (Priority: P2)

In addition to the actual temperature, the user can also see the "feels like"
temperature so they can make informed decisions about what to wear.

**Why this priority**: Feels-like temperature adds practical value beyond the raw
reading, but the app is still useful and complete without it.

**Independent Test**: With the app running, confirm that a secondary "Feels like X°"
value is displayed beneath or alongside the primary temperature, and that the value
differs from the actual temperature when conditions warrant (e.g., high wind chill or
humidity).

**Acceptance Scenarios**:

1. **Given** the app is displaying weather data,
   **When** the user views the Tidbyt screen,
   **Then** a "feels like" temperature value is shown as a secondary element, clearly
   differentiated from the actual current temperature.

2. **Given** a weather condition where feels-like differs from actual temperature,
   **When** the data is displayed,
   **Then** both values are shown simultaneously without truncation or overlap.

---

### User Story 3 - Automatic Data Refresh (Priority: P3)

The weather data shown on the device stays reasonably current throughout the day
without any manual action required from the user.

**Why this priority**: Stale data reduces trust and utility, but the app still delivers
value even before this is polished.

**Independent Test**: Leave the app running for longer than the configured refresh
interval and confirm the displayed temperature updates to reflect changed weather
conditions without restarting the device or app.

**Acceptance Scenarios**:

1. **Given** the app has been running for at least 10 minutes,
   **When** the underlying weather conditions change,
   **Then** the displayed data refreshes automatically to reflect the updated conditions.

2. **Given** the weather data source is temporarily unavailable,
   **When** the app attempts to refresh,
   **Then** the last successfully fetched data continues to display rather than showing
   a blank or error screen.

---

### Edge Cases

- What happens when the configured location cannot be resolved (invalid city name or
  coordinates)?
- How does the display handle very long condition labels (e.g., "Heavy Thunderstorm")
  on the small Tidbyt screen?
- What is shown during the initial load before any data has been fetched?
- How does the app behave when the temperature value is negative (below zero)?
- What icon is used for conditions that do not map to any predefined category?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display the current temperature for the configured location
  as the dominant visual element on the Tidbyt screen.
- **FR-002**: The app MUST display the current weather condition as a human-readable
  label (e.g., "Sunny", "Partly Cloudy", "Snow").
- **FR-003**: The app MUST display a visual icon or animation that corresponds to the
  current weather condition category.
- **FR-004**: The app MUST display the "feels like" temperature as a secondary element
  alongside the actual temperature.
- **FR-005**: The app MUST support at least the following condition categories with
  distinct icons: clear/sunny, partly cloudy, overcast/cloudy, rain, thunderstorm,
  snow, fog/mist.
- **FR-006**: The app MUST allow the location to be configured by typing a city name.
  London MUST be the default value shown in the configuration field; the app MUST
  display London weather immediately without any user setup required.
- **FR-007**: The app MUST display all temperatures in degrees Celsius (°C).
- **FR-008**: The app MUST automatically refresh weather data at a regular interval
  without requiring device restart.
- **FR-009**: The app MUST continue to display the last known data if a refresh
  attempt fails due to network unavailability.
- **FR-010**: All displayed information MUST fit within the Tidbyt screen dimensions
  without truncation of critical data (temperature and condition label).

### Key Entities

- **WeatherReading**: The fetched weather snapshot for a location at a point in time —
  includes actual temperature, feels-like temperature, condition category, and
  condition label.
- **Location**: The configured target location — a human-readable city name, postal
  code, or geographic coordinate pair.
- **ConditionIcon**: A visual asset (static image or looping animation) mapped to a
  specific weather condition category.
- **DisplayLayout**: The arrangement of temperature, feels-like, condition label, and
  icon within the 64 × 32 pixel Tidbyt display area.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A viewer standing near the Tidbyt can read the current temperature and
  weather condition within 3 seconds of looking at the screen, without approaching
  or interacting with the device.
- **SC-002**: The correct condition icon is displayed for 100% of the supported
  condition categories when tested with representative weather data for each.
- **SC-003**: The feels-like temperature is always visible alongside the actual
  temperature with no visual overlap, even when both values are three digits
  (e.g., −10° and −15°).
- **SC-004**: Weather data displayed is no older than 15 minutes under normal network
  conditions.
- **SC-005**: If the data source is unreachable, the last known weather values continue
  to be shown rather than a blank or broken display — verified by disabling network
  access during a refresh cycle.

## Assumptions

- The Tidbyt device has an internet connection available to fetch weather data.
- The location is configured once at setup time and does not change frequently; there
  is no need for a real-time location search UI on the device itself.
- London, UK (51.5074°N, 0.1278°W, Europe/London timezone) is the pre-configured
  default; the app displays useful weather data immediately without any user setup.
- The display area is 64 × 32 pixels (standard Tidbyt resolution); all layout
  decisions are based on this constraint.
- Animated icons (if used) loop continuously and are short (under 3 seconds per cycle)
  to remain visually ambient rather than distracting.
- Weather data is sourced from a publicly available weather API; the specific provider
  is an implementation decision and may change without requiring a spec update.
- A "condition category" maps multiple raw API condition codes to a single display
  category (e.g., "drizzle" and "moderate rain" both map to the "Rain" category).
- The app does not need to show hourly forecasts, wind speed, humidity, UV index, or
  any other extended weather data in this version.
