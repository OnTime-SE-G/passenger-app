import 'dart:async';

import 'package:latlong2/latlong.dart';

import 'demo_repository.dart';
import 'models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

/// API-backed repository with the same public surface as [DemoRepository].
///
/// Falls back to [DemoRepository] data when the API is unavailable.
/// Live tracking still uses the demo stream until the WebSocket integration
/// is complete (connect to ws://host:8004/v1/live?busId=...).
class ApiRepository {
  ApiRepository._();
  static final ApiRepository instance = ApiRepository._();

  final _api = ApiService.instance;
  final _demo = DemoRepository.instance;

  List<BusStop> _stops = [];
  List<BusRoute> _routes = [];
  List<Bus> _buses = [];
  bool _loaded = false;

  LatLng userLocation = const LatLng(6.9271, 79.8612);

  /// Call once at startup (e.g. from main.dart or a splash screen).
  Future<void> initialize() async {
    if (_loaded) return;
    try {
      await Future.wait([_loadStops(), _loadRoutes(), _loadBuses()]);
      _loaded = true;
    } catch (_) {
      // Fall through to demo data on total failure
    }
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

      final rawStops = r['stops'] as List<dynamic>;
      final stopIds = rawStops
          .map((s) {
            final coord = (s as Map<String, dynamic>)['coordinates'] as List<dynamic>;
            final loc = lngLatToLatLng(coord);
            return '${loc.latitude},${loc.longitude}';
          })
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

  Future<void> _loadBuses() async {
    final raw = await _api.getLiveBuses();
    _buses = raw
        .map((b) => Bus(
              id: b['id'].toString(),
              number: b['fleet_code']?.toString() ?? b['id'].toString(),
              routeId: b['route_id']?.toString() ?? '',
              driverName: 'Driver',
              capacity: (b['capacity'] as int?) ?? 50,
              status: b['status']?.toString(),
            ))
        .toList();
  }

  List<BusStop> get stops => _stops.isNotEmpty ? _stops : _demo.stops;
  List<BusRoute> get routes => _routes.isNotEmpty ? _routes : _demo.routes;
  List<Bus> get buses => _buses.isNotEmpty ? _buses : _demo.buses;

  /// Search routes between two coordinates via the G2 API.
  Future<Map<String, dynamic>> searchRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    int radius = 500,
  }) => _api.searchRoutes(
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
    // Reload fresh if empty
    await _loadBuses();
    return _buses.isNotEmpty ? _buses : _demo.buses;
  }

  /// Buses assigned to a specific route.
  Future<List<Map<String, dynamic>>> getBusesByRoute(String routeId) =>
      _api.getBusesByRoute(routeId);

  /// Routes serving a specific stop (live API call).
  Future<List<BusRoute>> fetchRoutesForStop(String stopId) async {
    try {
      final raw = await _api.getStopRoutes(stopId);
      return raw.map((r) => BusRoute(
        id: r['id'].toString(),
        code: r['route_number']?.toString() ?? r['id'].toString(),
        name: r['name'] as String,
        origin: (r['name'] as String).split('-').first.trim(),
        destination: (r['name'] as String).split('-').last.trim(),
        path: [],
        stopIds: [],
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// Buses for a route (live API call).
  Future<List<Bus>> fetchBusesForRoute(String routeId) async {
    try {
      final raw = await _api.getBusesByRoute(routeId);
      return raw.map((b) => Bus(
        id: b['id'].toString(),
        number: b['fleet_code']?.toString() ?? b['id'].toString(),
        routeId: routeId,
        driverName: 'Driver',
        capacity: (b['capacity'] as int?) ?? 50,
        status: b['status']?.toString(),
      )).toList();
    } catch (_) {
      return [];
    }
  }

  BusRoute routeById(String id) {
    try {
      // Match by numeric ID or by route name (API stops return names, not IDs)
      return _routes.firstWhere((r) => r.id == id || r.name == id);
    } catch (_) {
      return _demo.routeById(id);
    }
  }

  BusStop stopById(String id) {
    try {
      return _stops.firstWhere((s) => s.id == id);
    } catch (_) {
      return _demo.stopById(id);
    }
  }

  Bus busById(String id) {
    try {
      return _buses.firstWhere((b) => b.id == id);
    } catch (_) {
      return _demo.busById(id);
    }
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

  // Alerts — derived from live buses (like ontime-web notifications page).
  List<ServiceAlert> get alerts => _demo.alerts; // sync fallback

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
      for (final bus in buses) {
        final status  = bus['status']?.toString()     ?? '';
        final routeId = bus['route_id']?.toString()   ?? '';
        final route   = routeMap[routeId];
        final routeNum  = route?['route_number']?.toString() ?? routeId;
        final routeName = route?['name']?.toString()         ?? 'Unknown Route';
        final fleet     = bus['fleet_code']?.toString()      ?? bus['id'].toString();

        if (status == 'breakdown' || status == 'incident') {
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
          alerts.add(ServiceAlert(
            id: 'off-${bus['id']}',
            type: AlertType.info,
            routeCode: routeNum,
            title: 'Route $routeNum — Reduced Service',
            body: 'Bus $fleet is currently offline ($status). '
                'Fewer buses may be running on this route.',
            timestamp: DateTime.now(),
          ));
        }
      }
      return alerts.isNotEmpty ? alerts : _demo.alerts;
    } catch (_) {
      return _demo.alerts;
    }
  }

  /// Live bus position stream.
  /// 1. Seeds immediately from the REST /buses/live snapshot.
  /// 2. Then streams real-time updates from the G2 WebSocket service
  ///    (ws://localhost:8004/v1/live) — same approach as ontime-web's
  ///    tracking page (REST seed → socket updates).
  /// Falls back to the demo stream when WS is unavailable.
  Stream<BusPosition> watchBus(String busId) async* {
    // ── 1. REST snapshot seed ────────────────────────────────────────────────
    try {
      final raw = await _api.getLiveBuses();
      final match = raw.firstWhere(
        (b) => b['id'].toString() == busId ||
               b['fleet_code']?.toString().toUpperCase() == busId.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty &&
          match['latitude'] != null &&
          match['longitude'] != null) {
        yield BusPosition(
          busId: busId,
          location: LatLng(
            (match['latitude']  as num).toDouble(),
            (match['longitude'] as num).toDouble(),
          ),
          headingDeg:   (match['heading'] as num?)?.toDouble() ?? 0,
          speedKmh:     (match['speed']   as num?)?.toDouble() ?? 0,
          status: (match['status']?.toString() ?? '') == 'delayed'
              ? BusLiveStatus.delayed
              : BusLiveStatus.onTime,
          etaMinutes:   0,
          occupancyPct: 50,
          nextStopIndex: 0,
        );
      }
    } catch (_) {}

    // ── 2. WebSocket live stream ─────────────────────────────────────────────
    SocketService.instance.connect();
    bool receivedLive = false;

    await for (final loc in SocketService.instance.watchBus(busId).timeout(
      const Duration(seconds: 8),
      onTimeout: (sink) => sink.close(),
    )) {
      receivedLive = true;
      yield BusPosition(
        busId: loc.busId,
        location: LatLng(loc.lat, loc.lng),
        headingDeg:   loc.heading,
        speedKmh:     loc.speed,
        status: loc.status == 'delayed'
            ? BusLiveStatus.delayed
            : BusLiveStatus.onTime,
        etaMinutes:   loc.eta,
        occupancyPct: loc.occupancy == 'high'
            ? 88
            : loc.occupancy == 'medium' ? 55 : 25,
        nextStopIndex: 0,
      );
    }

    // ── 3. Fall back to demo stream if WS never fired ────────────────────────
    if (!receivedLive) {
      yield* _demo.watchBus(busId);
    }
  }

  BusPosition snapshotFor(String busId) => _demo.snapshotFor(busId);

  // Recent searches / saved routes / recent trips — delegate to demo data.
  List<RecentSearch> get recentSearches => _demo.recentSearches;
  List<SavedRoute>   get savedRoutes    => _demo.savedRoutes;
  List<RecentTrip>   get recentTrips    => _demo.recentTrips;
}
