import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'models.dart';
import '../services/api_service.dart';
import 'demo_repository.dart';

/// Live data repository backed by the ontime-g2 API.
/// Exposes the same public surface as [DemoRepository] so screens
/// only need to swap the singleton reference.
class ApiRepository {
  ApiRepository._();
  static final ApiRepository instance = ApiRepository._();

  final _api = ApiService();

  // ---------------------------------------------------------------------------
  // Cached collections (loaded once on first access)
  // ---------------------------------------------------------------------------

  List<BusRoute>? _routes;
  List<BusStop>? _stops;

  Future<List<BusRoute>> get routes async {
    if (_routes != null) return _routes!;
    try {
      final summaries = await _api.fetchRoutes();
      final parsed = <BusRoute>[];
      for (final s in summaries) {
        final geojson = await _api.fetchRouteGeoJson(s['id'] as int);
        if (geojson == null) continue;
        final features = geojson['features'] as List<dynamic>? ?? [];
        final lineFeature = features.firstWhere(
          (f) => f['properties']?['feature_type'] == 'route',
          orElse: () => null,
        );
        if (lineFeature == null) continue;
        final rawCoords = lineFeature['geometry']['coordinates'] as List<dynamic>;
        final path = rawCoords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        final stopFeatures = features
            .where((f) => f['properties']?['feature_type'] == 'stop')
            .toList()
          ..sort((a, b) => (a['properties']['order'] as int).compareTo(b['properties']['order'] as int));
        final stopIds = stopFeatures
            .map<String>((f) => 's${f['properties']['stop_id']}')
            .toList();
        final name = s['name'] as String? ?? '';
        final parts = name.split(RegExp(r'[-–→]'));
        parsed.add(BusRoute(
          id: 'r${s['id']}',
          code: '${s['id']}',
          name: name,
          origin: parts.first.trim(),
          destination: parts.last.trim(),
          path: path,
          stopIds: stopIds,
        ));
      }
      _routes = parsed.isNotEmpty ? parsed : DemoRepository.instance.routes;
    } catch (_) {
      _routes = DemoRepository.instance.routes;
    }
    return _routes!;
  }

  Future<List<BusStop>> get stops async {
    if (_stops != null) return _stops!;
    try {
      final raw = await _api.fetchAllStops();
      final parsed = raw.map((s) {
        final coords = s['coordinates'] as List<dynamic>?;
        final lat = (coords != null && coords.length >= 2) ? (coords[1] as num).toDouble() : 0.0;
        final lon = (coords != null && coords.length >= 2) ? (coords[0] as num).toDouble() : 0.0;
        final routeNames = (s['routes'] as List<dynamic>?)?.cast<String>() ?? [];
        return BusStop(
          id: 's${s['id']}',
          name: s['name'] as String? ?? '',
          address: s['name'] as String? ?? '',
          location: LatLng(lat, lon),
          routeIds: routeNames,
        );
      }).toList();
      _stops = parsed.isNotEmpty ? parsed : DemoRepository.instance.stops;
    } catch (_) {
      _stops = DemoRepository.instance.stops;
    }
    return _stops!;
  }

  List<Bus> get buses => DemoRepository.instance.buses;

  // ---------------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------------

  Future<BusRoute> routeById(String id) async {
    final list = await routes;
    return list.firstWhere((r) => r.id == id, orElse: () => DemoRepository.instance.routeById(id));
  }

  Future<BusStop> stopById(String id) async {
    final list = await stops;
    return list.firstWhere((s) => s.id == id, orElse: () => DemoRepository.instance.stopById(id));
  }

  Future<List<({BusStop stop, double meters})>> nearbyStops(LatLng from) async {
    try {
      final raw = await _api.fetchNearbyStops(from.latitude, from.longitude);
      const d = Distance();
      return raw.map((s) {
        final coords = s['coordinates'] as List<dynamic>?;
        final lat = (coords != null && coords.length >= 2) ? (coords[1] as num).toDouble() : 0.0;
        final lon = (coords != null && coords.length >= 2) ? (coords[0] as num).toDouble() : 0.0;
        final routeNames = (s['routes'] as List<dynamic>?)?.cast<String>() ?? [];
        final stop = BusStop(
          id: 's${s['id']}',
          name: s['name'] as String? ?? '',
          address: s['name'] as String? ?? '',
          location: LatLng(lat, lon),
          routeIds: routeNames,
        );
        return (stop: stop, meters: d.as(LengthUnit.Meter, from, stop.location));
      }).toList()
        ..sort((a, b) => a.meters.compareTo(b.meters));
    } catch (_) {
      return DemoRepository.instance.nearbyStops(from);
    }
  }

  // ---------------------------------------------------------------------------
  // Live bus stream — polls /api/v1/buses/live every 2 seconds
  // ---------------------------------------------------------------------------

  Stream<BusPosition> watchBus(String busId) async* {
    while (true) {
      try {
        final buses = await _api.fetchLiveBuses();
        final match = buses.where((b) => b['id']?.toString() == busId).firstOrNull;
        if (match != null) {
          final lat = (match['latitude'] as num?)?.toDouble() ?? 0;
          final lon = (match['longitude'] as num?)?.toDouble() ?? 0;
          yield BusPosition(
            busId: busId,
            location: LatLng(lat, lon),
            headingDeg: 0,
            speedKmh: 30,
            status: match['status'] == 'delayed' ? BusLiveStatus.delayed : BusLiveStatus.onTime,
            etaMinutes: 5,
            occupancyPct: 50,
            nextStopIndex: 0,
          );
        }
      } catch (_) {
        // fall through silently — no yield on error
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  BusPosition snapshotFor(String busId) => DemoRepository.instance.snapshotFor(busId);

  List<ServiceAlert> get alerts => DemoRepository.instance.alerts;
  List<RecentSearch> get recentSearches => DemoRepository.instance.recentSearches;
  List<SavedRoute> get savedRoutes => DemoRepository.instance.savedRoutes;
  List<RecentTrip> get recentTrips => DemoRepository.instance.recentTrips;

  LatLng get userLocation => DemoRepository.instance.userLocation;
}
