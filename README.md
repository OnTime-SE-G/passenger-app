# OnTime — Passenger App

> Real-time public transport tracking for passengers.  
> Part of the **OnTime** two-app suite (Passenger + Driver).

---

## Overview

**OnTime** is a Flutter mobile app that lets passengers find nearby bus stops, browse live bus routes, track buses in real time on a dark-themed map, and get accurate ETAs — all with a modern Signal Flux-inspired UI.

---

## Screens

| # | Screen | File |
|---|---|---|
| – | Splash (animated bus + map) | `lib/screens/splash_screen.dart` |
| 1 | Home (nearby buses, favorites, quick actions) | `lib/screens/home_screen.dart` |
| 2 | Map + Nearby Stops (full map, draggable sheet) | `lib/screens/nearby_stops_screen.dart` |
| 3 | Bus Stop Details | `lib/screens/stop_details_screen.dart` |
| 4 | Bus List (search + filter chips) | `lib/screens/bus_list_screen.dart` |
| 5 | Destination Filter (bottom sheet) | `lib/screens/destination_filter_sheet.dart` |
| 6 | Filtered Bus Selection (sorted by ETA, best option badge) | `lib/screens/filtered_bus_selection_screen.dart` |
| 7 | Live Tracking (dark map, glassmorphic panel, real-time stream) | `lib/screens/live_tracking_screen.dart` |
| – | Routes (Transit Flux layout, network density) | `lib/screens/routes_screen.dart` |
| – | Alerts (live alerts, severity-coded) | `lib/screens/alerts_screen.dart` |
| – | Profile | `lib/screens/profile_screen.dart` |

---

## Design System

Tokens live in `lib/theme/` — copy verbatim into the **Driver App** to stay pixel-identical.

| Token | Value |
|-------|-------|
| Background | `#11131C` (midnight indigo) |
| Surface layers | `#0C0E17` → `#32343E` (tonal z-axis) |
| Primary | `#BCC2FF` (lavender) |
| Secondary / Live | `#44D8F1` (cyan — signal color only) |
| Error / Delay | `#FFB4AB` |
| Primary container | `#142283` |
| Headlines | **Space Grotesk** (700–900) |
| Body / Labels | **Manrope** (400–800) |
| Card radius | `16 px` |
| Spacing grid | `4 / 8 / 12 / 16 / 24 / 32 px` |

### Reusable Widgets (`lib/widgets/`)

| Widget | Purpose |
|--------|---------|
| `OnTimeLogo` | Bus icon + "OnTime" wordmark (3 sizes) |
| `AppCard` | Dark surface card, tonal border |
| `PrimaryButton` / `SecondaryButton` | Gradient CTA / outlined |
| `StatusChip` | Pulsing LIVE / DELAYED / ARRIVING pill |
| `RouteBadge` | Route code badge (dark surface-bright) |
| `SearchField` | Dark input field |
| `SheetHandle` | Bottom sheet drag indicator |
| `UserLocationMarker` | Pulsing cyan dot |
| `StopMarker` | Stop circle on map |
| `LiveBusMarker` | Glowing cyan bus on map |

---

## Demo Database

`lib/data/demo_repository.dart` — in-memory singleton, no network needed.

```dart
DemoRepository.instance.stops              // List<BusStop>
DemoRepository.instance.routes             // List<BusRoute>
DemoRepository.instance.nearbyStops(point) // sorted by distance
DemoRepository.instance.busesForStop(id)
DemoRepository.instance.watchBus(busId)    // Stream<BusPosition> every ~1.2s
DemoRepository.instance.snapshotFor(busId) // one-shot for lists
```

**Swap to Postgres:** implement the same method signatures backed by
`LISTEN/NOTIFY` or WebSocket — zero screen changes required.

---

## Map

Uses `flutter_map` + **CARTO Dark Matter** tiles (no API key).  
Swap to Google Maps SDK when keys are available; all marker widgets and polyline
logic are tile-provider-agnostic.

---

## Logo & Branding

The **OnTime** logo (`assets/images/ontime_logo.png`) is a glowing cyan bus with
an integrated clock badge. Use the `OnTimeLogo` widget in code:

```dart
OnTimeLogo(size: OnTimeLogoSize.normal)   // icon + wordmark
OnTimeLogo(size: OnTimeLogoSize.small)    // compact (app bar)
OnTimeLogo(size: OnTimeLogoSize.large)    // hero usage
OnTimeLogoImage(width: 120)              // PNG asset version
```

---

## Running

```bash
cd passenger_app
flutter pub get

# Web (Chrome) — fastest for dev
flutter run -d chrome

# Android emulator (start emulator first in Android Studio)
flutter run -d emulator-5554

# Physical Android device (USB debugging on)
flutter run -d <device-id>
```

Requires **Flutter 3.19+**.

---

## Build

```bash
# Debug APK (fast, includes dev tools)
flutter build apk --debug

# Release APK (optimised, requires signing config)
flutter build apk --release

# Output path
# build/app/outputs/flutter-apk/app-debug.apk
```

---

## Project Structure

```
passenger_app/
├── assets/
│   └── images/
│       └── ontime_logo.png
├── lib/
│   ├── main.dart                  # App entry point → SplashScreen
│   ├── data/
│   │   ├── models.dart            # BusStop, BusRoute, Bus, BusPosition
│   │   └── demo_repository.dart   # In-memory DB + live streams
│   ├── theme/
│   │   ├── app_colors.dart        # Full color token set
│   │   ├── app_spacing.dart       # Spacing + radius constants
│   │   ├── app_typography.dart    # Space Grotesk + Manrope scale
│   │   └── app_theme.dart         # ThemeData builder
│   ├── widgets/                   # Reusable primitives
│   └── screens/                   # All 10 screens + shell
└── pubspec.yaml
```

---

## Navigation Flow

```
SplashScreen
    │
    ▼
AppShell (bottom nav: Home | Live Map | Routes | Alerts | Profile)
    │
    ├── HomeScreen
    │       │
    │       └── NearbyStopsScreen (map + draggable sheet)
    │               │
    │               └── StopDetailsScreen
    │                       │
    │                       └── BusListScreen
    │                               │
    │                               ├── DestinationFilterSheet (modal)
    │                               │       │
    │                               │       └── FilteredBusSelectionScreen
    │                               │
    │                               └── LiveTrackingScreen ◄─ real-time stream
    │
    ├── LiveTrackingScreen (direct from Live Map tab)
    ├── RoutesScreen
    ├── AlertsScreen
    └── ProfileScreen
```

---

## Roadmap

- [ ] Connect to central Postgres database (replace `DemoRepository`)
- [ ] Driver App (shared design system already in place)
- [ ] Push notifications for ETA alerts
- [ ] Google Maps SDK integration (swap tile provider)
- [ ] User authentication
- [ ] Saved favourite stops
- [ ] Offline mode with cached routes
