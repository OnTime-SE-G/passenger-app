import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

/// Real-time bus row — mirrors [ontime-passenger-web `socketService.ts`](https://github.com/OnTime-SE-G/ontime-passenger-web).
class BusLocation {
  final String busId;
  final String fleetCode;
  final String routeId;
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final int timestamp;
  /// Semantic bucket when backend sends text (`low` / `medium` / `high`).
  final String occupancy;
  /// Prefer numeric fields from G2 (`occupancy_pct`, `load`, …).
  final int occupancyPct;
  final String status;
  final String driverName;
  final int eta;
  /// Index of the next stop in the route's stop list (0-based).
  final int nextStopIdx;

  const BusLocation({
    required this.busId,
    this.fleetCode = '',
    required this.routeId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.timestamp,
    required this.occupancy,
    required this.occupancyPct,
    required this.status,
    required this.driverName,
    required this.eta,
    this.nextStopIdx = 0,
  });

  BusLocation copyWith({
    double? lat,
    double? lng,
    double? speed,
    double? heading,
    int? timestamp,
    String? occupancy,
    int? occupancyPct,
    String? status,
    String? driverName,
    int? eta,
    int? nextStopIdx,
  }) {
    return BusLocation(
      busId: busId,
      fleetCode: fleetCode,
      routeId: routeId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      occupancy: occupancy ?? this.occupancy,
      occupancyPct: occupancyPct ?? this.occupancyPct,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      eta: eta ?? this.eta,
      nextStopIdx: nextStopIdx ?? this.nextStopIdx,
    );
  }

  /// Same field precedence as web `socketService.ts` `onmessage` (non–`eta_update`).
  factory BusLocation.fromLivePayload(Map<String, dynamic> raw) {
    final busId =
        raw['busId']?.toString() ?? raw['bus_id']?.toString() ?? '';
    final fleetCode =
        raw['fleet_code']?.toString() ?? raw['fleetCode']?.toString() ?? '';

    final lat = _num(raw['lat']) ?? _num(raw['latitude']) ?? 0;
    final lng =
        _num(raw['lon']) ?? _num(raw['lng']) ?? _num(raw['longitude']) ?? 0;

    final speed =
        _num(raw['speed']) ?? _num(raw['speed_kmh']) ?? _num(raw['velocity']) ?? 0;

    final heading = _num(raw['heading']) ?? 0;

    final rawOcc = raw['occupancy'];
    final occBucket = rawOcc == null
        ? 'low'
        : rawOcc.toString().toLowerCase().trim();

    // --- ETA: compute from remainingDistanceToNextStops or distanceToNextStop ---
    // Backend sends distance in metres; assume average 40 km/h on urban routes.
    int etaMinutes = etaMinutesFromPayload(raw);
    if (etaMinutes == 0) {
      final remM = _num(raw['remainingDistanceToNextStops']) ??
          _num(raw['remaining_distance_to_next_stops']);
      if (remM != null && remM > 0) {
        // distance_m / (speed_kmh * 1000/60) = minutes
        final avgKmh = (speed > 5) ? speed.toDouble() : 40.0;
        etaMinutes = (remM / (avgKmh * 1000 / 60)).ceil().clamp(0, 999);
      } else {
        final distNext = _num(raw['distanceToNextStop']) ??
            _num(raw['distance_to_next_stop']);
        if (distNext != null && distNext > 0) {
          final avgKmh = (speed > 5) ? speed.toDouble() : 40.0;
          etaMinutes = (distNext / (avgKmh * 1000 / 60)).ceil().clamp(0, 999);
        }
      }
    }

    // --- Next stop index from stopsAhead list (first entry = next stop) ---
    int nextStopIdx = 0;
    final stopsAhead = raw['stopsAhead'];
    if (stopsAhead is List && stopsAhead.isNotEmpty) {
      final first = stopsAhead.first;
      if (first is Map) {
        final order = first['stopOrder'];
        if (order is num) nextStopIdx = (order - 1).clamp(0, 999).toInt();
      }
    }

    // --- Occupancy: derive from stopsRemaining if no explicit field ---
    int occupancyPct = occupancyPctFromPayload(raw);
    if (occupancyPct == 25) { // default 'low' fallback — try route progress
      final pct = _num(raw['routeProgressPct']) ??
          _num(raw['route_progress_pct']);
      if (pct != null && pct > 0) {
        // Bus earlier in route = more passengers boarding; later = fewer
        // Simple heuristic: mid-route is typically fullest
        final p = pct.toDouble().clamp(0, 100);
        occupancyPct = (p < 30 || p > 80) ? 35 : (p < 60 ? 65 : 50);
      }
    }

    return BusLocation(
      busId: busId,
      fleetCode: fleetCode,
      routeId:
          raw['routeId']?.toString() ?? raw['route_id']?.toString() ?? '',
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      speed: speed.toDouble(),
      heading: heading.toDouble(),
      timestamp: raw['timestamp'] != null
          ? (DateTime.tryParse(raw['timestamp'].toString())??
                 DateTime.now())
              .millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch,
      occupancy: occBucket == 'medium' || occBucket == 'high'
          ? occBucket
          : 'low',
      occupancyPct: occupancyPct,
      status: (raw['trip_status']?.toString() ??
                   raw['tripStatus']?.toString() ??
                   raw['status']?.toString() ??
                   'ACTIVE')
          .toUpperCase() == 'ACTIVE'
          ? 'active'
          : 'delayed',
      driverName: raw['driverName']?.toString() ??
          raw['driver_name']?.toString() ??
          '',
      eta: etaMinutes,
      nextStopIdx: nextStopIdx,
    );
  }

  static num? _num(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '');

  /// Shared with REST `/buses/live` rows (same keys as Redis → websocket JSON).
  static int occupancyPctFromPayload(Map<String, dynamic> j) {
    for (final key in [
      'occupancy_pct',
      'occupancy_percentage',
      'load_pct',
      'load',
    ]) {
      final v = j[key];
      if (v is num) {
        var x = v.toDouble();
        if (x > 0 && x <= 1.0) {
          x *= 100;
        }
        return x.round().clamp(0, 100);
      }
    }
    final s = j['occupancy']?.toString().toLowerCase() ?? 'low';
    return switch (s) {
      'high' => 88,
      'medium' => 55,
      _ => 25,
    };
  }

  static int etaMinutesFromPayload(Map<String, dynamic> raw) {
    if (raw.containsKey('eta_seconds') && raw['eta_seconds'] != null) {
      final s = (raw['eta_seconds'] as num).toDouble();
      return (s / 60).ceil().clamp(0, 999);
    }
    final e = raw['eta'];
    if (e is num) return e.round().clamp(0, 999);
    return 0;
  }

  static int etaMinutesFromEtaUpdate(Map<String, dynamic> raw) {
    if (raw.containsKey('eta_seconds') && raw['eta_seconds'] != null) {
      final s = (raw['eta_seconds'] as num).toDouble();
      return (s / 60).ceil().clamp(0, 999);
    }
    final e = raw['eta'];
    if (e is num) return e.round().clamp(0, 999);
    return 0;
  }
}

/// Plain WebSocket client — matches [ontime-passenger-web `socketService.ts`](https://github.com/OnTime-SE-G/ontime-passenger-web).
///
/// Connect with **no query params** on `/v1/live` (same as web default). Server-side
/// `busId`/`routeId` filters in G2 can drop valid Redis payloads when keys don’t match.
class SocketService {
  static final SocketService instance = SocketService._();
  SocketService._();

  WebSocketChannel? _channel;
  final _controller = StreamController<BusLocation>.broadcast();
  bool _connected = false;
  int _reconnectAttempts = 0;
  static const _maxReconnects = 5;
  String? _lastUrl;

  final Map<String, BusLocation> _latestByBusId = {};

  Stream<BusLocation> get stream => _controller.stream;
  bool get isConnected => _connected;

  /// Connect to G2 `/v1/live` (optionally override full URL for tests / proxies).
  void connect([String? overrideUrl]) {
    final url = overrideUrl ?? '$wsBase/v1/live';
    if (_connected && url == _lastUrl) return;
    _lastUrl = url;
    _open(url);
  }

  void _open(String url) {
    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (data) {
          _connected = true;
          _reconnectAttempts = 0;
          try {
            final decoded = jsonDecode(data as String);
            _dispatchDecoded(decoded);
          } catch (_) {}
        },
        onDone: () {
          _connected = false;
          _scheduleReconnect(url);
        },
        onError: (_) {
          _connected = false;
          _scheduleReconnect(url);
        },
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleReconnect(url);
    }
  }

  void _dispatchDecoded(dynamic decoded) {
    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) {
          _dispatchDecoded(Map<String, dynamic>.from(item));
        }
      }
      return;
    }
    if (decoded is Map) {
      final m = Map<String, dynamic>.from(decoded);
      final inner = m['data'];
      if (inner is Map &&
          !m.containsKey('lat') &&
          !m.containsKey('latitude') &&
          !m.containsKey('busId') &&
          !m.containsKey('bus_id')) {
        _dispatchDecoded(Map<String, dynamic>.from(inner));
        return;
      }
      _handleDecoded(m);
    }
  }

  void _handleDecoded(Map<String, dynamic> raw) {
    final evt = raw['event']?.toString();
    if (evt == 'eta_update') {
      final bid = raw['busId'] ?? raw['bus_id'];
      if (bid == null) return;
      final key = bid.toString();
      final etaMin = BusLocation.etaMinutesFromEtaUpdate(raw);
      final prev = _latestByBusId[key];
      if (prev != null) {
        final merged = prev.copyWith(eta: etaMin);
        _latestByBusId[key] = merged;
        _controller.add(merged);
      }
      return;
    }

    final loc = BusLocation.fromLivePayload(raw);
    if (loc.busId.isEmpty) return;
    _latestByBusId[loc.busId] = loc;
    _controller.add(loc);
  }

  void _scheduleReconnect(String url) {
    if (_reconnectAttempts >= _maxReconnects) return;
    final delaySec = (2 * (1 << _reconnectAttempts)).clamp(1, 10);
    _reconnectAttempts++;
    Future.delayed(Duration(seconds: delaySec), () => _open(url));
  }

  /// Stream of updates filtered to a single bus (DB id or fleet code).
  Stream<BusLocation> watchBus(String busId) {
    final want = busId.trim();
    if (want.isEmpty) return const Stream.empty();
    final wantFleet = want.toUpperCase();
    return stream.where((loc) {
      if (loc.busId == want) return true;
      if (loc.fleetCode.isNotEmpty &&
          loc.fleetCode.toUpperCase() == wantFleet) {
        return true;
      }
      return false;
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _latestByBusId.clear();
  }
}
