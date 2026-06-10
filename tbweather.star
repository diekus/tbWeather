"""tbWeather — current weather display for Tidbyt."""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")

# ── Constants ─────────────────────────────────────────────────────────────────

CACHE_TTL        = 900    # seconds (15 min) — weather data, satisfies SC-004
GEOCODING_TTL    = 86400  # seconds (24 hr)  — city → coordinates
API_URL          = "https://api.open-meteo.com/v1/forecast"
GEOCODING_URL    = "https://geocoding-api.open-meteo.com/v1/search"
ICON_SIZE        = 12     # pixels (width and height)
DISPLAY_W        = 64
DISPLAY_H        = 32
DEFAULT_LOCATION = "London"

# ── WMO weather code → condition key ─────────────────────────────────────────

WMO_CONDITIONS = {
    0:  "clear",
    1:  "mainly_clear",
    2:  "partly_cloudy",
    3:  "overcast",
    45: "fog",
    48: "fog",
    51: "drizzle",
    53: "drizzle",
    55: "drizzle",
    56: "freezing_drizzle",
    57: "freezing_drizzle",
    61: "rain",
    63: "rain",
    65: "rain",
    66: "freezing_rain",
    67: "freezing_rain",
    71: "snow",
    73: "snow",
    75: "snow",
    77: "snow",
    80: "rain_showers",
    81: "rain_showers",
    82: "rain_showers",
    85: "snow_showers",
    86: "snow_showers",
    95: "thunderstorm",
    96: "heavy_thunderstorm",
    99: "heavy_thunderstorm",
}

# ── Condition key → display label ─────────────────────────────────────────────

CONDITION_LABELS = {
    "clear":             "Clear",
    "mainly_clear":      "Mainly Clear",
    "partly_cloudy":     "Partly Cloudy",
    "overcast":          "Overcast",
    "fog":               "Fog",
    "drizzle":           "Drizzle",
    "freezing_drizzle":  "Freezing Drizzle",
    "rain":              "Rain",
    "freezing_rain":     "Freezing Rain",
    "snow":              "Snow",
    "rain_showers":      "Showers",
    "snow_showers":      "Snow Showers",
    "thunderstorm":      "Thunderstorm",
    "heavy_thunderstorm":"Thunderstorm",
    "unknown":           "N/A",
}

# ── Icon key grouping — multiple condition keys share one icon asset ───────────

ICON_KEY = {
    "clear":             "clear",
    "mainly_clear":      "clear",
    "partly_cloudy":     "partly_cloudy",
    "overcast":          "overcast",
    "fog":               "fog",
    "drizzle":           "rain",
    "freezing_drizzle":  "rain",
    "rain":              "rain",
    "freezing_rain":     "rain",
    "rain_showers":      "rain",
    "snow":              "snow",
    "snow_showers":      "snow",
    "thunderstorm":      "thunderstorm",
    "heavy_thunderstorm":"thunderstorm",
    "unknown":           "unknown",
}

# ── Icon data — base64-encoded 12×12 px RGB PNG ───────────────────────────────

ICON_DATA = {
    "clear": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAOklEQVR42mNgQAX/T4AQToAmh1MpxBjshkGEkFXA1aGoxlSBYh4uY1AMI0oRUdaR4HDCQUBaYOKKFgAaZ3jd16I77QAAAABJRU5ErkJggg==",
    "fog": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAGElEQVR42mNgIBK098zGg0hRNGodlUwCAJz9dZU95k2yAAAAAElFTkSuQmCC",
    "overcast": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAJUlEQVR42mNgIBVcunQdjghIY1eKSwVCHX4VUHXUU0SUmwYhAADXKqitjLVEUgAAAABJRU5ErkJggg==",
    "partly_cloudy": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAMUlEQVR42mNgAIP/Z6AIJ4CrwKkOTQUJ6oDg0qXrQIRdKUQOGSFUYMqRqwiXOoZBCwB7GXsZlzhmQgAAAABJRU5ErkJggg==",
    "rain": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAL0lEQVR42mNgIAlMXH8dDRFWga4OlwqEOvwqoOqIUgQBUdP+42KgAMLqqGcSFQAAxbV7hawEA2UAAAAASUVORK5CYII=",
    "snow": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAL0lEQVR42mNgIAlMXH8dDRFWga4OlwqEOvwqoOqIUgQB////x8VAAYTVUc8kKgAAHwmILabRnEQAAAAASUVORK5CYII=",
    "thunderstorm": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAANklEQVR42mNggIGUlApkxIAJ0FRgUYdVBYo6PCoQ6ggqAqkjShEa+H8HhPABYlUQVkcl6/AAABZ8XEXQu0dcAAAAAElFTkSuQmCC",
    "unknown": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAI0lEQVR42mNgIAlcunQdDWFXgV+EOEUEDaaFCtICghqKyAcAhxI7iUJcW6wAAAAASUVORK5CYII=",
}

# ── Helpers ───────────────────────────────────────────────────────────────────

def wmo_to_condition(code):
    """Map a WMO weather code integer to a canonical condition key."""
    return WMO_CONDITIONS.get(code, "unknown")

def _icon_for(condition):
    """Return raw PNG bytes for the given condition key."""
    key  = ICON_KEY.get(condition, "unknown")
    data = ICON_DATA.get(key) or ICON_DATA["unknown"]
    return base64.decode(data)

# ── Schema ────────────────────────────────────────────────────────────────────

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id      = "location",
                name    = "Location",
                desc    = "City name to display weather for (e.g. London, Paris, Tokyo).",
                icon    = "locationDot",
                default = DEFAULT_LOCATION,
            ),
        ],
    )

# ── Render states ─────────────────────────────────────────────────────────────

def render_error():
    """ERROR state — shown when geocoding or the weather API call fails."""
    return render.Root(
        child = render.Box(
            width  = DISPLAY_W,
            height = DISPLAY_H,
            child  = render.WrappedText(
                content = "No data",
                font    = "tb-8",
                color   = "#FF4444",
                width   = 58,
                align   = "center",
            ),
        ),
    )

def render_weather(reading):
    """POPULATED state — icon + temperature + feels-like + condition + location."""
    temp_text       = "%d°" % reading["temp_c"]
    feels_text      = "(~%d°)" % reading["feels_like_c"]
    condition_label = reading["condition_label"]
    location        = reading["location"]
    icon_src        = _icon_for(reading["condition"])

    # Marquee scrolls only when condition label exceeds display width
    condition_widget = render.Marquee(
        child = render.Text(
            content = condition_label,
            font    = "tb-8",
            color   = "#AAAAAA",
        ),
        width            = DISPLAY_W,
        scroll_direction = "horizontal",
        delay            = 80,
    )

    return render.Root(
        child = render.Column(
            children = [
                # Row 1: icon + temperature + feels-like in parentheses
                render.Row(
                    children = [
                        render.Image(
                            src    = icon_src,
                            width  = ICON_SIZE,
                            height = ICON_SIZE,
                        ),
                        render.Box(width = 2, height = ICON_SIZE),
                        render.Text(
                            content = temp_text,
                            font    = "6x13",
                            color   = "#FFFFFF",
                        ),
                        render.Box(width = 2, height = 1),
                        render.Text(
                            content = feels_text,
                            font    = "tb-8",
                            color   = "#888888",
                        ),
                    ],
                    cross_align = "center",
                ),
                # Row 2: condition label (scrolls if too wide)
                condition_widget,
                # Row 3: location name
                render.Text(
                    content = location,
                    font    = "tb-8",
                    color   = "#666666",
                ),
            ],
        ),
    )

# ── Data fetching and parsing ─────────────────────────────────────────────────

def geocode(city_name):
    """Resolve a city name to lat/lng/timezone via Open-Meteo geocoding."""
    resp = http.get(
        GEOCODING_URL,
        params = {
            "name":     city_name,
            "count":    "1",
            "language": "en",
            "format":   "json",
        },
        ttl_seconds = GEOCODING_TTL,
    )
    if resp.status_code != 200:
        return None
    data    = json.decode(resp.body())
    results = data.get("results")
    if not results:
        return None
    first = results[0]
    return {
        "lat":      str(first.get("latitude", "")),
        "lng":      str(first.get("longitude", "")),
        "timezone": str(first.get("timezone", "UTC")),
        "name":     str(first.get("name", city_name)),
    }

def fetch_weather(lat, lng, timezone):
    """Call Open-Meteo and return the raw response body, or None on failure."""
    resp = http.get(
        API_URL,
        params = {
            "latitude":         str(lat),
            "longitude":        str(lng),
            "current":          "temperature_2m,apparent_temperature,weather_code",
            "temperature_unit": "celsius",
            "timezone":         str(timezone),
        },
        ttl_seconds = CACHE_TTL,
    )
    if resp.status_code != 200:
        return None
    return resp.body()

def parse_weather_response(body):
    """Decode JSON body and return a WeatherReading dict, or None if fields are missing."""
    data    = json.decode(body)
    current = data.get("current")
    if not current:
        return None

    temp   = current.get("temperature_2m")
    feels  = current.get("apparent_temperature")
    wmo    = current.get("weather_code")

    if temp == None or feels == None or wmo == None:
        return None

    condition = wmo_to_condition(int(wmo))
    return {
        "temp_c":          int(temp),
        "feels_like_c":    int(feels),
        "wmo_code":        int(wmo),
        "condition":       condition,
        "condition_label": CONDITION_LABELS.get(condition, "N/A"),
    }

# ── Entry point ───────────────────────────────────────────────────────────────

def main(config):
    city   = config.get("location") or DEFAULT_LOCATION
    coords = geocode(city)
    if coords == None:
        return render_error()

    body = fetch_weather(coords["lat"], coords["lng"], coords["timezone"])
    if body == None:
        return render_error()

    reading = parse_weather_response(body)
    if reading == None:
        return render_error()

    reading["location"] = coords["name"]
    return render_weather(reading)
