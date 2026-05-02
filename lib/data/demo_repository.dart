import 'dart:async';
import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'models.dart';

/// Demo in-memory database.
///
/// Replace with a Postgres-backed repository later. The public surface
/// (`stops`, `routes`, `buses`, `watchBus(...)`, `nearbyStops(...)`) should
/// stay stable so screens don't have to change when we swap implementations.
class DemoRepository {
  DemoRepository._();
  static final DemoRepository instance = DemoRepository._();

  // Centered around a generic downtown grid for demo purposes.
  static const LatLng _center = LatLng(12.9716, 77.5946);

  /// Simulated current user location.
  LatLng userLocation = const LatLng(12.9718, 77.5955);

  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------

  late final List<BusStop> stops = [
    BusStop(
      id: 's1',
      name: 'Willow St. Crossing',
      address: 'Willow St & 4th Ave',
      location: _offset(0.0012, -0.0008),
      routeIds: ['r1', 'r2'],
    ),
    BusStop(
      id: 's2',
      name: 'Central Market',
      address: 'Market Rd',
      location: _offset(0.0020, 0.0015),
      routeIds: ['r1', 'r3'],
    ),
    BusStop(
      id: 's3',
      name: 'Parkside Terminal',
      address: 'Park Ave',
      location: _offset(-0.0018, 0.0024),
      routeIds: ['r2', 'r4'],
    ),
    BusStop(
      id: 's4',
      name: 'Riverside Loop',
      address: 'River Rd',
      location: _offset(0.0035, -0.0030),
      routeIds: ['r3'],
    ),
    BusStop(
      id: 's5',
      name: 'North Station',
      address: 'North Blvd',
      location: _offset(-0.0040, -0.0012),
      routeIds: ['r1', 'r4'],
    ),
    BusStop(
      id: 's6',
      name: 'Tech Park Gate',
      address: 'Innovation Dr',
      location: _offset(0.0050, 0.0050),
      routeIds: ['r2', 'r3'],
    ),
  ];

  late final List<BusRoute> routes = [
    BusRoute(
      id: 'r1',
      code: '24B',
      name: 'Downtown Express',
      origin: 'Willow St.',
      destination: 'North Station',
      path: _buildPath([
        _offset(0.0012, -0.0008),
        _offset(0.0020, 0.0015),
        _offset(-0.0040, -0.0012),
      ]),
      stopIds: ['s1', 's2', 's5'],
    ),
    BusRoute(
      id: 'r2',
      code: '102',
      name: 'Parkside Link',
      origin: 'Willow St.',
      destination: 'Tech Park',
      path: _buildPath([
        _offset(0.0012, -0.0008),
        _offset(-0.0018, 0.0024),
        _offset(0.0050, 0.0050),
      ]),
      stopIds: ['s1', 's3', 's6'],
    ),
    BusRoute(
      id: 'r3',
      code: 'M15',
      name: 'Riverside Loop',
      origin: 'Central Market',
      destination: 'Tech Park',
      path: _buildPath([
        _offset(0.0020, 0.0015),
        _offset(0.0035, -0.0030),
        _offset(0.0050, 0.0050),
      ]),
      stopIds: ['s2', 's4', 's6'],
    ),
    BusRoute(
      id: 'r4',
      code: '402',
      name: 'North Circular',
      origin: 'Parkside',
      destination: 'North Station',
      path: _buildPath([
        _offset(-0.0018, 0.0024),
        _offset(-0.0040, -0.0012),
      ]),
      stopIds: ['s3', 's5'],
    ),
  ];

  late final List<Bus> buses = [
    const Bus(id: 'b1', number: '24B-01', routeId: 'r1', driverName: 'John Doe', capacity: 48),
    const Bus(id: 'b2', number: '24B-02', routeId: 'r1', driverName: 'Priya R.', capacity: 48),
    const Bus(id: 'b3', number: '102-11', routeId: 'r2', driverName: 'Alex Kim', capacity: 52),
    const Bus(id: 'b4', number: 'M15-07', routeId: 'r3', driverName: 'Sara Lee', capacity: 44),
    const Bus(id: 'b5', number: '402-03', routeId: 'r4', driverName: 'Miguel O.', capacity: 50),
  ];

  final List<RecentSearch> recentSearches = [
    RecentSearch(from: 'Home', to: 'Tech Park Gate', at: DateTime.now().subtract(const Duration(hours: 2))),
    RecentSearch(from: 'Central Market', to: 'North Station', at: DateTime.now().subtract(const Duration(days: 1))),
    RecentSearch(from: 'Willow St. Crossing', to: 'Parkside Terminal', at: DateTime.now().subtract(const Duration(days: 2))),
  ];

  late final List<ServiceAlert> alerts = [
    ServiceAlert(
      id: 'a1',
      type: AlertType.disruption,
      routeCode: '120',
      title: 'Route 120 — Service Suspended',
      body: 'Service suspended between Pettah and Wellawatte due to road works. Use route 138 as alternative.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    ServiceAlert(
      id: 'a2',
      type: AlertType.delay,
      routeCode: '882',
      title: 'Route 882 — 15 min Delay',
      body: 'All buses on the Colombo–Piliyandala route are running approximately 15 minutes late due to heavy traffic near Nugegoda junction.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    ServiceAlert(
      id: 'a3',
      type: AlertType.info,
      routeCode: '138',
      title: 'Route 138 — Extra Service',
      body: 'Additional buses added on the Fort–Maharagama route during peak hours (7–9 AM, 5–7 PM) until Friday.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ServiceAlert(
      id: 'a4',
      type: AlertType.info,
      routeCode: '24B',
      title: 'Route 24B — Schedule Change',
      body: 'Revised timetable in effect from Monday. Last service now departs at 22:30 instead of 23:00.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  final List<SavedRoute> savedRoutes = [
    SavedRoute(routeCode: '882', name: 'Colombo – Piliyandala'),
    SavedRoute(routeCode: '138', name: 'Fort – Maharagama'),
  ];

  final List<RecentTrip> recentTrips = [
    RecentTrip(from: 'Central Station', to: 'Market Square', routeCode: '882', at: DateTime.now().subtract(const Duration(hours: 1))),
    RecentTrip(from: 'City Hall', to: 'University Jct.', routeCode: '138', at: DateTime.now().subtract(const Duration(days: 1))),
    RecentTrip(from: 'Market Square', to: 'Shopping Mall', routeCode: '120', at: DateTime.now().subtract(const Duration(days: 2))),
  ];

  // ---------------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------------

  BusRoute routeById(String id) => routes.firstWhere((r) => r.id == id);
  BusStop stopById(String id) => stops.firstWhere((s) => s.id == id);
  Bus busById(String id) => buses.firstWhere((b) => b.id == id);

  List<Bus> busesForStop(String stopId) {
    final stop = stopById(stopId);
    return buses.where((b) => stop.routeIds.contains(b.routeId)).toList();
  }

  List<Bus> busesForRoute(String routeId) =>
      buses.where((b) => b.routeId == routeId).toList();

  /// Stops sorted by distance from a given point.
  List<({BusStop stop, double meters})> nearbyStops(LatLng from) {
    const d = Distance();
    final list = stops
        .map((s) => (stop: s, meters: d.as(LengthUnit.Meter, from, s.location)))
        .toList()
      ..sort((a, b) => a.meters.compareTo(b.meters));
    return list;
  }

  // ---------------------------------------------------------------------------
  // Live stream — simulates real-time GPS pings for a given bus.
  // Swap for a Postgres LISTEN/NOTIFY or websocket feed in production.
  // ---------------------------------------------------------------------------

  final Map<String, int> _tickByBus = {};
  final Map<String, BusLiveStatus> _statusByBus = {};

  Stream<BusPosition> watchBus(String busId) async* {
    final bus = busById(busId);
    final route = routeById(bus.routeId);
    final rnd = Random(busId.hashCode);

    _tickByBus[busId] ??= rnd.nextInt(route.path.length ~/ 2);
    _statusByBus[busId] ??= BusLiveStatus.values[rnd.nextInt(3)];

    while (true) {
      final t = _tickByBus[busId]! % route.path.length;
      final next = (t + 1) % route.path.length;
      final a = route.path[t];
      final b = route.path[next];

      final bearing = _bearing(a, b);
      final speed = 28 + rnd.nextDouble() * 22; // 28–50 km/h
      final occupancy = 35 + rnd.nextInt(55);
      final nextStopIndex = _nextStopIndexFromTick(route, t);
      final eta = max(1, (route.path.length - t) ~/ 6 + rnd.nextInt(3));

      yield BusPosition(
        busId: busId,
        location: b,
        headingDeg: bearing,
        speedKmh: speed,
        status: _statusByBus[busId]!,
        etaMinutes: eta,
        occupancyPct: occupancy,
        nextStopIndex: nextStopIndex,
      );

      _tickByBus[busId] = t + 1;
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
  }

  /// Expose a one-shot snapshot (used for list screens).
  BusPosition snapshotFor(String busId) {
    final bus = busById(busId);
    final route = routeById(bus.routeId);
    final rnd = Random(busId.hashCode);
    final tick = _tickByBus[busId] ?? rnd.nextInt(route.path.length);
    final status = _statusByBus[busId] ?? BusLiveStatus.values[rnd.nextInt(3)];
    final eta = max(1, (route.path.length - tick) ~/ 6 + rnd.nextInt(3));
    return BusPosition(
      busId: busId,
      location: route.path[tick % route.path.length],
      headingDeg: 0,
      speedKmh: 32 + rnd.nextDouble() * 16,
      status: status,
      etaMinutes: eta,
      occupancyPct: 40 + rnd.nextInt(50),
      nextStopIndex: _nextStopIndexFromTick(route, tick),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static LatLng _offset(double dLat, double dLng) =>
      LatLng(_center.latitude + dLat, _center.longitude + dLng);

  /// Densify a polyline by linearly interpolating extra points between nodes.
  static List<LatLng> _buildPath(List<LatLng> nodes) {
    const steps = 20;
    final out = <LatLng>[];
    for (var i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i];
      final b = nodes[i + 1];
      for (var s = 0; s < steps; s++) {
        final t = s / steps;
        out.add(LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        ));
      }
    }
    out.add(nodes.last);
    return out;
  }

  static int _nextStopIndexFromTick(BusRoute r, int tick) {
    if (r.stopIds.length <= 1) return 0;
    final seg = (r.path.length - 1) / (r.stopIds.length - 1);
    final idx = (tick / seg).floor().clamp(0, r.stopIds.length - 1);
    return idx;
  }

  static double _bearing(LatLng a, LatLng b) {
    final dy = b.latitude - a.latitude;
    final dx = b.longitude - a.longitude;
    return (atan2(dx, dy) * 180 / pi + 360) % 360;
  }
}
