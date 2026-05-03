import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final String _base = AppConfig.g2BaseUrl;

  Future<List<Map<String, dynamic>>> fetchRoutes() async {
    final res = await http.get(Uri.parse('$_base/api/v1/routes'));
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(decoded as List);
  }

  Future<Map<String, dynamic>?> fetchRouteGeoJson(int routeId) async {
    final res = await http.get(Uri.parse('$_base/api/v1/routes/$routeId'));
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchNearbyStops(double lat, double lon, {int radiusM = 500}) async {
    final url = '$_base/api/v1/stops/nearby?lat=$lat&lon=$lon&radius_m=$radiusM';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(decoded as List);
  }

  Future<List<Map<String, dynamic>>> fetchAllStops() async {
    final res = await http.get(Uri.parse('$_base/api/v1/stops'));
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(decoded as List);
  }

  Future<List<Map<String, dynamic>>> fetchLiveBuses() async {
    final res = await http.get(Uri.parse('$_base/api/v1/buses/live'));
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(decoded as List);
  }
}
