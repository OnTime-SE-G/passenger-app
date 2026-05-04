import 'dart:async';
import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'demo_repository.dart';
import 'models.dart';
import '../services/api_service.dart';

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
              number: b['id'].toString(),
              routeId: b['route_id']?.toString() ?? '',
              driverName: 'Driver',
              capacity: (b['capacity'] as int?) ?? 50,
            ))
        .toList();
  }

  List<BusStop> get stops => _stops.isNotEmpty ? _stops : _demo.stops;
  List<BusRoute> get routes => _routes.isNotEmpty ? _routes : _demo.routes;
  List<Bus> get buses => _buses.isNotEmpty ? _buses : _demo.buses;

  BusRoute routeById(String id) {
    try {
      return _routes.firstWhere((r) => r.id == id);
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

  // Alerts — delegates to demo data until the backend exposes an alerts endpoint.
  List<ServiceAlert> get alerts => _demo.alerts;

  // Live tracking — delegates to demo stream until WebSocket is integrated.
  // To wire real-time: connect to ws://<host>:8004/v1/live?busId=<busId>
  // and yield BusPosition events from incoming JSON messages.
  Stream<BusPosition> watchBus(String busId) => _demo.watchBus(busId);

  BusPosition snapshotFor(String busId) => _demo.snapshotFor(busId);
}
