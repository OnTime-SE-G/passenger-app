import 'dart:async';

import 'package:latlong2/latlong.dart';

import 'models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

/// API-backed repository. Loads from [ApiService]; empty when the API fails or
/// returns no data (no bundled seed data).
class ApiRepository {
  ApiRepository._();
  static final ApiRepository instance = ApiRepository._();

  final _api = ApiService.instance;

  List<BusStop> _stops = [];
  List<BusRoute> _routes = [];
  List<Bus> _buses = [];
  bool _loaded = false;

  LatLng userLocation = const LatLng(6.9271, 79.8612);

  /// Call once at startup (e.g. from main.dart or a splash screen).
  Future<void> initialize() async {
    if (_loaded) return;
    try {
      await _loadStops();
    } catch (_) {}
    try {
      await _loadRoutes();
    } catch (_) {}
    try {
      await _loadBuses();
    } catch (_) {}
    _loaded = true;
  }

  /// Reloads stops, routes, and live buses from the API.
  Future<void> refresh() async {
    try {
      await _loadStops();
    } catch (_) {}
    try {
      await _loadRoutes();
    } catch (_) {}
    try {
      await _loadBuses();
    } catch (_) {}
    _loaded = true;
  }

  Future<void> _loadStops() async {
    final raw = await _api.getAllStops();
    _stops = raw
        .where((s) => s['coordinates'] != null)
        .map((s) {
          final coords = s['coordinates'] as List<dynamic>;
          return BusStop(
            id: s['id'].toString(),
            name: s['name'] as String,
            address: s['name'] as String,
            location: lngLatToLatLng(coords),
            routeIds: List<String>.from(
              (s['routes'] as List<dynamic>? ?? []).map((r) => r.toString()),
            ),
          );
        })
        .toList();
  }

  Future<void> _loadRoutes() async {
    final raw = await _api.getAllTransitData();
    _routes = raw.values.map((dynamic v) {
      final r = v as Map<String, dynamic>;
      final rawPath = r['path'] as List<dynamic>;
      final path = rawPath
          .map((c) => lngLatToLatLng(c as List<dynamic>))
          .toList();

      final rawStops = r['stops'] as List<dynamic>? ?? const [];
      final stopIds = rawStops
          .map((s) => _canonicalStopIdForTransitStop(s as Map<String, dynamic>))
          .toList();

      return BusRoute(
        id: r['id'].toString(),
        code: r['number']?.toString() ?? r['id'].toString(),
        name: r['name'] as String,
        origin: (r['name'] as String).split(' - ').first,
        destination: (r['name'] as String).split(' - ').last,
        path: path,
        stopIds: stopIds,
      );
    }).toList();
  }

  /// Transit route payloads usually omit stop `id`; match `/stops` rows by
  /// coordinates so [stopById] resolves names and map markers correctly.
  String _canonicalStopIdForTransitStop(Map<String, dynamic> s) {
    final direct = s['id'];
    if (direct != null) return direct.toString();
    final coord = s['coordinates'] as List<dynamic>?;
    if (coord == null || coord.length < 2) return '';
    final loc = lngLatToLatLng(coord);
    const tol = 1e-4;
    for (final stop in _stops) {
      if ((stop.location.latitude - loc.latitude).abs() <= tol &&
          (stop.location.longitude - loc.longitude).abs() <= tol) {
        return stop.id;
      }
    }
    return '${loc.latitude},${loc.longitude}';
  }

  Future<void> _loadBuses() async {
    final raw = await _api.getLiveBuses();
    _buses = raw
        .map((b) => Bus(
              id: b['id'].toString(),
              number: b['fleet_code']?.toString() ?? b['id'].toString(),
              routeId: b['route_id']?.toString() ?? '',
              driverName: b['driver_name']?.toString() ??
                  b['fleet_code']?.toString() ??
                  '',
              capacity: (b['capacity'] as int?) ?? 50,
              status: b['status']?.toString(),
            ))
        .toList();
  }

  List<BusStop> get stops => _stops;
  List<BusRoute> get routes => _routes;
  List<Bus> get buses => _buses;

  /// Search routes between two coordinates via the G2 API.
  Future<Map<String, dynamic>> searchRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    int radius = 500,
  }) =>
      _api.searchRoutes(
        startLat: startLat,
        startLon: startLon,
        endLat: endLat,
        endLon: endLon,
        radius: radius,
      );

  /// Live buses from the G2 API as typed Bus objects.
  Future<List<Bus>> getLiveBuses() async {
    if (!_loaded) await initialize();
    if (_buses.isNotEmpty) return _buses;
    try {
      await _loadBuses();
    } catch (_) {}
    return _buses;
  }

  /// Buses assigned to a specific route.
  Future<List<Map<String, dynamic>>> getBusesByRoute(String routeId) =>
      _api.getBusesByRoute(routeId);

  /// Routes serving a specific stop (live API call).
  Future<List<BusRoute>> fetchRoutesForStop(String stopId) async {
    try {
      final raw = await _api.getStopRoutes(stopId);
      return raw
          .map((r) => BusRoute(
                id: r['id'].toString(),
                code: r['route_number']?.toString() ?? r['id'].toString(),
                name: r['name'] as String,
                origin: (r['name'] as String).split('-').first.trim(),
                destination: (r['name'] as String).split('-').last.trim(),
                path: [],
                stopIds: [],
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Buses for a route (live API call).
  Future<List<Bus>> fetchBusesForRoute(String routeId) async {
    try {
      final raw = await _api.getBusesByRoute(routeId);
      return raw
          .map((b) => Bus(
                id: b['id'].toString(),
                number: b['fleet_code']?.toString() ?? b['id'].toString(),
                routeId: routeId,
                driverName: b['driver_name']?.toString() ??
                    b['fleet_code']?.toString() ??
                    '',
                capacity: (b['capacity'] as int?) ?? 50,
                status: b['status']?.toString(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  BusRoute routeById(String id) {
    for (final r in _routes) {
      if (r.id == id || r.name == id) return r;
    }
    return BusRoute(
      id: id,
      code: id,
      name: 'Route $id',
      origin: '',
      destination: '',
      path: const [],
      stopIds: const [],
    );
  }

  BusStop stopById(String id) {
    for (final s in _stops) {
      if (s.id == id) return s;
    }
    final comma = id.indexOf(',');
    if (comma > 0 && comma < id.length - 1) {
      final lat = double.tryParse(id.substring(0, comma));
      final lng = double.tryParse(id.substring(comma + 1));
      if (lat != null && lng != null) {
        var bestName = 'Stop';
        const tol = 1e-4;
        for (final s in _stops) {
          if ((s.location.latitude - lat).abs() <= tol &&
              (s.location.longitude - lng).abs() <= tol) {
            bestName = s.name;
            break;
          }
        }
        return BusStop(
          id: id,
          name: bestName,
          address: '',
          location: LatLng(lat, lng),
          routeIds: const [],
        );
      }
    }
    return BusStop(
      id: id,
      name: 'Stop',
      address: '',
      location: userLocation,
      routeIds: const [],
    );
  }

  Bus busById(String id) {
    final needle = id.trim();
    for (final b in _buses) {
      if (b.id == needle ||
          b.number.toUpperCase() == needle.toUpperCase()) {
        return b;
      }
    }
    return Bus(
      id: id,
      number: id,
      routeId: '',
      driverName: '',
      capacity: 0,
    );
  }

  List<Bus> busesForStop(String stopId) {
    final stop = stopById(stopId);
    return buses.where((b) => stop.routeIds.contains(b.routeId)).toList();
  }

  List<Bus> busesForRoute(String routeId) =>
      buses.where((b) => b.routeId == routeId).toList();

  List<({BusStop stop, double meters})> nearbyStops(LatLng from) {
    const d = Distance();
    final list = stops
        .map(
          (s) => (
            stop: s,
            meters: d.as(LengthUnit.Meter, from, s.location),
          ),
        )
        .toList()
      ..sort((a, b) => a.meters.compareTo(b.meters));
    return list;
  }

  /// Sync list for header badges; empty until [fetchAlerts] has run elsewhere.
  List<ServiceAlert> get alerts => const [];

  /// Loads live buses + routes and derives service alerts — mirrors
  /// ontime-web's `notifications/page.tsx` deriveAlerts() logic.
  Future<List<ServiceAlert>> fetchAlerts() async {
    try {
      final buses = await _api.getLiveBuses();
      final routes = await _api.getRoutes();
      final routeMap = <String, Map<String, dynamic>>{
        for (final r in routes) r['id'].toString(): r,
      };

      final alerts = <ServiceAlert>[];
      final routesWithIssues = <String>{};

      for (final bus in buses) {
        final status = bus['status']?.toString() ?? '';
        final routeId = bus['route_id']?.toString() ?? '';
        final route = routeMap[routeId];
        final routeNum = route?['route_number']?.toString() ?? routeId;
        final routeName = route?['name']?.toString() ?? 'Unknown Route';
        final fleet = bus['fleet_code']?.toString() ?? bus['id'].toString();

        if (status == 'breakdown' || status == 'incident') {
          routesWithIssues.add(routeId);
          alerts.add(ServiceAlert(
            id: 'inc-${bus['id']}',
            type: AlertType.disruption,
            routeCode: routeNum,
            title: 'Route $routeNum — Bus Breakdown',
            body: 'Bus $fleet on the $routeName route reported a breakdown. '
                'Service on this route may be disrupted.',
            timestamp: DateTime.now(),
          ));
        } else if (status == 'delayed') {
          routesWithIssues.add(routeId);
          alerts.add(ServiceAlert(
            id: 'dly-${bus['id']}',
            type: AlertType.delay,
            routeCode: routeNum,
            title: 'Route $routeNum — Running Late',
            body: 'Bus $fleet on the $routeName route is currently delayed. '
                'Please expect longer wait times.',
            timestamp: DateTime.now(),
          ));
        } else if (status == 'inactive' || status == 'maintenance') {
          routesWithIssues.add(routeId);
          alerts.add(ServiceAlert(
            id: 'off-${bus['id']}',
            type: AlertType.inactive,
            routeCode: routeNum,
            title: 'Route $routeNum — Bus Offline',
            body: 'Bus $fleet is currently offline. '
                'Fewer buses may be running on this route.',
            timestamp: DateTime.now(),
          ));
        }
      }

      // Add "Operating Normally" info alerts for active routes with no issues
      for (final route in routes) {
        final routeId = route['id']?.toString() ?? '';
        if (routesWithIssues.contains(routeId)) continue;
        final routeNum = route['route_number']?.toString() ?? routeId;
        final routeName = route['name']?.toString() ?? 'Route $routeNum';
        final hasActiveBus = buses.any((b) =>
          b['route_id']?.toString() == routeId &&
          (b['status']?.toString() ?? '') == 'active');
        if (!hasActiveBus) continue;
        alerts.add(ServiceAlert(
          id: 'ok-$routeId',
          type: AlertType.info,
          routeCode: routeNum,
          title: 'Route $routeNum — Operating Normally',
          body: '$routeName is running on schedule with no reported disruptions.',
          timestamp: DateTime.now(),
        ));
      }

      return alerts;
    } catch (_) {
      return [];
    }
  }

  BusLiveStatus _busLiveStatusFromApi(String? s) {
    if ((s ?? '').toLowerCase() == 'delayed') return BusLiveStatus.delayed;
    return BusLiveStatus.onTime;
  }

  BusPosition? _busPositionFromRest(Map<String, dynamic> match, String resolvedBusId) {
    // lat/lng may be null when the bus hasn't sent GPS yet (backend live_map is empty)
    final rawLat = match['latitude'];
    final rawLng = match['longitude'];
    if (rawLat == null || rawLng == null) return null;
    final lat = (rawLat as num).toDouble();
    final lng = (rawLng as num).toDouble();
    // Sanity-check: 0,0 is the ocean — treat as missing
    if (lat == 0 && lng == 0) return null;
    return BusPosition(
      busId: resolvedBusId,
      location: LatLng(lat, lng),
      headingDeg: (match['heading'] as num?)?.toDouble() ?? 0,
      speedKmh:
          ((match['speed_kmh'] ?? match['speed']) as num?)?.toDouble() ?? 0,
      status: _busLiveStatusFromApi(match['status']?.toString()),
      etaMinutes: BusLocation.etaMinutesFromPayload(match),
      occupancyPct: BusLocation.occupancyPctFromPayload(match),
      nextStopIndex: 0,
      driverDisplay: match['driver_name']?.toString() ??
          match['fleet_code']?.toString() ??
          '',
    );
  }

  BusPosition _busPositionFromSocket(BusLocation loc, String canonicalBusId) {
    return BusPosition(
      busId: canonicalBusId,
      location: LatLng(loc.lat, loc.lng),
      headingDeg: loc.heading,
      speedKmh: loc.speed,
      status: _busLiveStatusFromApi(loc.status),
      etaMinutes: loc.eta,
      occupancyPct: loc.occupancyPct,
      nextStopIndex: loc.nextStopIdx,
      driverDisplay: loc.driverName,
    );
  }

  /// Live bus position stream.
  /// 1. Seeds immediately from the REST /buses/live snapshot (same matching rules as
  ///    [ontime-passenger-web `/tracking`](https://github.com/OnTime-SE-G/ontime-passenger-web)).
  /// 2. Streams Redis-backed payloads from G2 websocket (`G2_WS_URL/v1/live`), including
  ///    `event: "eta_update"` handling inside [SocketService].
  Stream<BusPosition> watchBus(String busId, {String? routeDbId}) async* {
    var resolvedId = busId.trim();
    var match = <String, dynamic>{};

    try {
      final raw = await _api.getLiveBuses();
      match = raw.cast<Map<String, dynamic>>().firstWhere(
            (b) =>
                b['id'].toString() == busId ||
                b['fleet_code']?.toString().toUpperCase() ==
                    busId.toUpperCase() ||
                (routeDbId != null &&
                    routeDbId.trim().isNotEmpty &&
                    b['route_id']?.toString() == routeDbId.trim()),
            orElse: () => <String, dynamic>{},
          );
      if (match.isNotEmpty) {
        resolvedId = match['id'].toString();
        // Only yield REST snapshot when coordinates are actually present
        final restPos = _busPositionFromRest(match, resolvedId);
        if (restPos != null) yield restPos;
      }
    } catch (_) {}

    // Connect to websocket using plain `/v1/live` (no query params) — matches
    // passenger-web `socketService.ts`. Server-side busId/routeId filters can
    // silently drop messages when payload keys don't match camelCase expectation.
    SocketService.instance.connect();

    await for (final loc in SocketService.instance.watchBus(resolvedId)) {
      yield _busPositionFromSocket(loc, resolvedId);
    }
  }

  /// Stream of ALL live bus positions from the websocket.
  /// Connects once and emits every bus update as it arrives.
  /// Used by the Live Map tab to show all buses moving on the map.
  Stream<BusLocation> streamAllBuses() {
    SocketService.instance.connect();
    return SocketService.instance.stream;
  }

  BusPosition snapshotFor(String busId) {
    try {
      final needle = busId.trim();
      final bus = _buses.firstWhere(
        (b) =>
            b.id == needle ||
            b.number.toUpperCase() == needle.toUpperCase(),
      );
      BusRoute? route;
      for (final r in _routes) {
        if (r.id == bus.routeId || r.name == bus.routeId) {
          route = r;
          break;
        }
      }
      if (route != null && route.path.isNotEmpty) {
        return BusPosition(
          busId: bus.id,
          location: route.path.first,
          headingDeg: 0,
          speedKmh: 0,
          status: BusLiveStatus.onTime,
          etaMinutes: 0,
          occupancyPct: 0,
          nextStopIndex: 0,
          driverDisplay: '',
        );
      }
    } catch (_) {}
    return BusPosition(
      busId: busId,
      location: userLocation,
      headingDeg: 0,
      speedKmh: 0,
      status: BusLiveStatus.onTime,
      etaMinutes: 0,
      occupancyPct: 0,
      nextStopIndex: 0,
      driverDisplay: '',
    );
  }

  List<RecentSearch> get recentSearches => const [];
  List<SavedRoute> get savedRoutes => const [];
  List<RecentTrip> get recentTrips => const [];
}
