import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Web: defaults to localhost:8000.
// Android emulator: flutter run --dart-define=G2_BASE_URL=http://10.0.2.2:8000
// Physical device: flutter run --dart-define=G2_BASE_URL=http://192.168.x.x:8000
const String _base = String.fromEnvironment(
  'G2_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

// WebSocket service
const String wsBase = String.fromEnvironment(
  'G2_WS_URL',
  defaultValue: 'ws://localhost:8004',
);

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  static const _timeout = Duration(seconds: 10);

  Future<List<Map<String, dynamic>>> getRoutes() async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/routes'))
        .timeout(_timeout);
    _check(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  Future<Map<String, dynamic>> getRouteTransitData(String routeId) async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/routes/$routeId/transit-data'))
        .timeout(_timeout);
    _check(res);
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> getAllTransitData() async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/routes/all-transit-data'))
        .timeout(_timeout);
    _check(res);
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> getRouteStops(String routeId) async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/routes/$routeId/stops'))
        .timeout(_timeout);
    _check(res);
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<List<Map<String, dynamic>>> getAllStops() async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/stops'))
        .timeout(_timeout);
    _check(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  Future<List<Map<String, dynamic>>> getNearbyStops(
    double lat,
    double lon, {
    int radius = 500,
  }) async {
    final uri = Uri.parse(
      '$_base/api/v1/stops/nearby?lat=$lat&lon=$lon&radius_m=$radius',
    );
    final res = await http.get(uri).timeout(_timeout);
    _check(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  Future<List<Map<String, dynamic>>> getStopRoutes(String stopId) async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/stops/$stopId/routes'))
        .timeout(_timeout);
    _check(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  Future<Map<String, dynamic>> searchRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    int radius = 500,
  }) async {
    final uri = Uri.parse(
      '$_base/api/v1/routes/search'
      '?start_lat=$startLat&start_lon=$startLon'
      '&end_lat=$endLat&end_lon=$endLon&radius_m=$radius',
    );
    final res = await http.get(uri).timeout(_timeout);
    _check(res);
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<List<Map<String, dynamic>>> getLiveBuses() async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/buses/live'))
        .timeout(_timeout);
    _check(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  Future<List<Map<String, dynamic>>> getBusesByRoute(String routeId) async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/routes/$routeId/buses'))
        .timeout(_timeout);
    _check(res);
    final body = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    return List<Map<String, dynamic>>.from(body['buses'] as List? ?? []);
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
  }
}

// Helper to parse LatLng from backend coordinate array [lng, lat]
LatLng lngLatToLatLng(List<dynamic> coord) =>
    LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
