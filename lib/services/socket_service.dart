import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

/// Real-time bus location received from the G2 WebSocket service.
/// Field mapping matches what ontime-web's socketService.ts normalises.
class BusLocation {
  final String busId;
  final String routeId;
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final int timestamp;
  final String occupancy; // 'low' | 'medium' | 'high'
  final String status;    // 'active' | 'delayed'
  final String driverName;
  final int eta;

  const BusLocation({
    required this.busId,
    required this.routeId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.timestamp,
    required this.occupancy,
    required this.status,
    required this.driverName,
    required this.eta,
  });

  /// Normalize field names: G2 sends snake_case; ontime-web also handles both.
  factory BusLocation.fromJson(Map<String, dynamic> j) => BusLocation(
        busId:      j['busId']?.toString()   ?? j['bus_id']?.toString()   ?? '',
        routeId:    j['routeId']?.toString()  ?? j['route_id']?.toString()  ?? '',
        lat:        (j['lat']   as num?)?.toDouble() ?? 0,
        lng:        (j['lon']   as num?)?.toDouble() ??
                    (j['lng']   as num?)?.toDouble() ?? 0,
        speed:      (j['speed']   as num?)?.toDouble() ?? 0,
        heading:    (j['heading'] as num?)?.toDouble() ?? 0,
        timestamp:  (j['timestamp'] as num?)?.toInt() ??
                    DateTime.now().millisecondsSinceEpoch,
        occupancy:  j['occupancy']?.toString()  ?? 'low',
        status:     j['status']?.toString()     ?? 'active',
        driverName: j['driverName']?.toString() ?? '',
        eta:        (j['eta'] as num?)?.toInt() ?? 0,
      );
}

/// Singleton WebSocket client that connects to the G2 websocket-service
/// (`ws://localhost:8004/v1/live`) and broadcasts [BusLocation] updates.
///
/// Mirrors the behaviour of ontime-web's `socketService.ts`:
///   • Single shared connection, auto-reconnects with exponential back-off
///   • Filters per-bus via [watchBus]
class SocketService {
  static final SocketService instance = SocketService._();
  SocketService._();

  WebSocketChannel? _channel;
  final _controller = StreamController<BusLocation>.broadcast();
  bool _connected = false;
  int _reconnectAttempts = 0;
  static const _maxReconnects = 5;
  String? _lastUrl;

  Stream<BusLocation> get stream => _controller.stream;
  bool get isConnected => _connected;

  /// Connect to the WebSocket service. Safe to call multiple times.
  void connect([String? url]) {
    url ??= '$wsBase/v1/live';
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
            final raw = jsonDecode(data as String);
            if (raw is Map<String, dynamic>) {
              _controller.add(BusLocation.fromJson(raw));
            }
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

  void _scheduleReconnect(String url) {
    if (_reconnectAttempts >= _maxReconnects) return;
    final delaySec = (2 * (1 << _reconnectAttempts)).clamp(1, 10);
    _reconnectAttempts++;
    Future.delayed(Duration(seconds: delaySec), () => _open(url));
  }

  /// Stream of updates filtered to a single bus.
  Stream<BusLocation> watchBus(String busId) =>
      stream.where((loc) => loc.busId == busId);

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _connected = false;
  }
}
