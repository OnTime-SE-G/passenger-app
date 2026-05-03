class AppConfig {
  static const String g2BaseUrl = 'http://10.0.2.2:8000';
  static const String mapboxToken =
      String.fromEnvironment('MAPBOX_TOKEN', defaultValue: 'YOUR_MAPBOX_ACCESS_TOKEN');
}
