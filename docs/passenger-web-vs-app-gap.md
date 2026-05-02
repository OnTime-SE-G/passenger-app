# On Time Passenger: Web UI vs Flutter App Gap Analysis

This document lists what the **Flutter passenger app** (`lib/`) does **not** include or fully match compared to the **On Time passenger web** reference (sidebar dashboard, Colombo-area demo).

Scope: feature and layout parity vs the provided web mockups—not backend or production readiness.

---

## 1. Navigation and shell

| Web reference | Flutter app |
|---------------|-------------|
| **Persistent left sidebar** with logo (“On Time / PUBLIC TRANSPORT”), primary nav items with active-state rail, labels: Search Routes, Nearby Stops, Bus Routes, Live Tracking, **Alerts**, **Profile**, plus **My Account** at bottom | **`AppShell`** uses a **floating bottom pill navigation** with **four** tabs only: Search, Stops, Routes, Live (`app_shell.dart`) |
| **Alerts** and **Profile** as first-class destinations in the sidebar | **No Alerts screen** and **no Profile screen** in the codebase |
| Separate **My Account** entry distinct from Profile | No account area; nothing equivalent |

---

## 2. Global header (all main pages)

| Web reference | Flutter app |
|---------------|-------------|
| **Page title** in the main area (e.g. “Nearby Stops”, “Live Tracking”) alongside header actions | Mixed: some screens use logo + sparse actions instead of mirroring web’s unified title strip |
| **Refresh** control (circular arrows) | **No global refresh** in headers (`onPressed` often empty or omitted) |
| **Notifications bell with numeric badge** (e.g. “4”) | Search home shows a bell **without badge** (`passenger_search_home_screen.dart`); other tabs don’t mirror web’s global trio |
| **User / profile avatar** in the top-right | **No** avatar entry point to Profile / account |

---

## 3. Search Routes (“Where to?”)

| Web reference | Flutter app |
|---------------|-------------|
| **Desktop split**: route card **left**, **large map right** occupying ~half the viewport | **Single column**: card, recent searches, then **stacked map preview** below (~280px tall) (`passenger_search_home_screen.dart`) |
| Origin preset label **“My Location”** (with GPS/target affordance) | Default text **“Current Location”** with similar icon; wording differs |
| **Swap** control between origin and destination | Swap icon shown as **non-interactive** `CircleAvatar` (no swap handler wired) |
| **Leave Now** / **Options** as real trip planning entry points | `onPressed: () {}` **stubs only** |

**Already roughly aligned:** “Where to?” headline, subtitle, destination field, Search Route primary CTA, recent-style list (app uses “Recent searches”), map chip “Live Network: Good Service”, locate control on preview map.

---

## 4. Nearby Stops

| Web reference | Flutter app |
|---------------|-------------|
| **Search bar over the map**: “Search bus stops…” filtering the list/map | No stop-name search overlay on the map view (`nearby_stops_screen.dart`) |
| Map shows **multiple colored route lines** overlaid | Map shows **stops + user location only**—**no route polylines** on this screen |
| **Zoom +/-** controls on the map chrome | Only a **single “my location” FAB**—no +/- zoom strip |
| Main header mirrors web app bar (**Refresh, badged bell, avatar**) | **Back** glass bar + optional title text; web-style global actions absent |

**Already roughly aligned:** Full-screen map, draggable bottom sheet (“Nearby stops”, “N found”), stop list with route badges, progression to stop details.

---

## 5. Bus Routes (“Active Routes”)

| Web reference | Flutter app |
|---------------|-------------|
| **Wide header search**: “Search routes…” as a dominant field spanning the top | **`IconButton` search only**, `onPressed: () {}` **no-op** (`nearby_bus_routes_screen.dart`) |
| Globally styled header (refresh, notifications, profile) | Logo + ineffective search icon only |

**Already roughly aligned:** “Active Routes”, bus count subtitle, sort chips (Shortest ETA / Distance / Route Number), destination filter field, route cards with code badge, Active/Delayed, ETA, bus type, **Select Bus** opening live tracking.

---

## 6. Live Tracking

| Web reference | Flutter app |
|---------------|-------------|
| **Detail panel anchored on the right** of the map | **Panel on the left** (width-capped overlay) (`live_tracking_screen.dart`) |
| **Zoom +/-** (and visible **scale**/distance affordance like “300 m”) | **No** baked-in +/- or scale widget in screen code |
| Stops timeline with **minute estimates** (~6 min, ~15 min…) for upcoming legs | Stop rows use **“Passed” / “Next stop” / “Scheduled”** copy—**not** per-stop minute ETAs like the web overlay |

**Already roughly aligned:** Full map, route polyline progression, animated bus marker, frosted panel with route number + on-time/delayed, destination line, driver name, ETA / speed / load, ordered stop list.

---

## 7. Service Alerts

| Web reference | Flutter app |
|---------------|-------------|
| Dedicated **“Service Alerts”** view: subtitle “Live updates for routes…”, **Live** pill, categorized cards (**DISRUPTION**, **DELAY**, **INFO**), route tags, timestamps, long-form descriptions | **Entire surface missing**: no alerts model, repository, or screen |

---

## 8. Profile

| Web reference | Flutter app |
|---------------|-------------|
| **Profile** page: avatar, name (“Passenger”), location (**Colombo, Sri Lanka**), **Edit** |
| **Saved routes** section with starred routes |
| **Recent trips** (from → to, route, relative time) |
| **Preferences** toggles: accessibility (low-floor), notifications for saved routes, show delays on map | **Nothing implemented**: no profile UI, persisted preferences, saved routes, or trip history presentation |

---

## 9. Map provider and attribution (cosmetic)

| Web reference | Flutter app |
|---------------|-------------|
| **Mapbox** tiles + attribution in screenshots | **`AppMapTiles`**: Carto **Voyager** (`map_widgets.dart`) |

This is branding/provider choice rather than UX logic, but it differs from the web reference.

---

## 10. Summary: highest-impact gaps

1. **No Alerts** module (list, categories, routes, timestamps).  
2. **No Profile** module (identity, saved routes, recent trips, preferences).  
3. **Navigation model**: sidebar + **Alerts** + **Profile** + **My Account** vs **4-tab bottom nav** only.  
4. **Global chrome**: refresh, **badged** notifications, profile avatar—not consistently implemented.  
5. **Responsive / web layout**: Search home split view; Nearby Stops map search & route overlays & zoom chrome.  
6. **Live Tracking**: panel side, zoom/scale controls, granular stop ETA copy.  
7. **Stubs**: swap origin–destination, Leave Now / Options, header search where web expects real flows.

---

*Generated from codebase review (`lib/screens`, `lib/main.dart`, navigation in `app_shell.dart`) vs On Time passenger web reference designs.*
