import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

/// Compile-time override (`flutter run --dart-define=MAPBOX_TOKEN=...`).
/// Must be a const [String.fromEnvironment] — non-const calls throw on web.
const String _kMapboxTokenFromDefine =
    String.fromEnvironment('MAPBOX_TOKEN', defaultValue: '');

/// Mapbox public token: `--dart-define=MAPBOX_TOKEN=pk...` or `assets/env/mapbox.env`.
String mapboxAccessToken() {
  final fromDefine = _kMapboxTokenFromDefine.trim();
  if (fromDefine.isNotEmpty) return fromDefine;
  try {
    final fromFile = dotenv.env['MAPBOX_TOKEN']?.trim();
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
  } on Error {
    // Tests / isolates that never called dotenv.load().
  }
  return '';
}

/// Mapbox Streets raster tiles — same style family as ontime-web (`streets-v12`).
///
/// Rendering uses [flutter_map]; basemap tiles are served by Mapbox (not Carto/OSM direct).
class AppMapTiles extends StatelessWidget {
  const AppMapTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final token = mapboxAccessToken();
    assert(() {
      if (token.isEmpty) {
        debugPrint(
          'MAPBOX_TOKEN is empty. Set assets/env/mapbox.env or '
          '--dart-define=MAPBOX_TOKEN=... — Mapbox tiles will not load.',
        );
      }
      return true;
    }());
    return TileLayer(
      urlTemplate:
          'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}{r}?access_token=$token',
      retinaMode: MediaQuery.of(context).devicePixelRatio > 1.5,
      userAgentPackageName: 'com.ontime.passenger_app',
      tileSize: 512,
      zoomOffset: -1,
    );
  }
}

/// User dot — blue fill + white ring (see web home map marker).
class UserLocationMarker extends StatefulWidget {
  const UserLocationMarker({super.key});

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Container(
                width: 36 + 28 * t,
                height: 36 + 28 * t,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bus stop markers — white dot + primary ring (web KML-style markers).
class StopMarker extends StatelessWidget {
  const StopMarker({super.key, this.selected = false, this.passed = false});
  final bool selected;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final bg = passed ? AppColors.routePassed : Colors.white;
    final ring = passed ? AppColors.routePassed : AppColors.primary;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: selected ? 3 : 2.5),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 4),
        ],
      ),
    );
  }
}

/// Live bus marker — circular badge using route accent (`route.color` on web).
class LiveBusMarker extends StatefulWidget {
  const LiveBusMarker({super.key, this.heading = 0});
  final double heading;

  @override
  State<LiveBusMarker> createState() => _LiveBusMarkerState();
}

class _LiveBusMarkerState extends State<LiveBusMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1 - _c.value).clamp(0.0, 0.45),
              child: Container(
                width: 56 * _c.value,
                height: 56 * _c.value,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Transform.rotate(
              angle: widget.heading * 3.14159265359 / 180,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

FlutterMap buildMap({
  required MapController controller,
  required LatLng center,
  double zoom = 15,
  required List<Widget> layers,
  bool interactive = true,
}) {
  final token = mapboxAccessToken();
  return FlutterMap(
    mapController: controller,
    options: MapOptions(
      initialCenter: center,
      initialZoom: zoom,
      interactionOptions: InteractionOptions(
        flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
      ),
    ),
    children: [
      ...layers,
      if (token.isNotEmpty)
        RichAttributionWidget(
          attributions: [
            const TextSourceAttribution(
              'Mapbox',
              prependCopyright: true,
            ),
            const TextSourceAttribution(
              'OpenStreetMap',
              prependCopyright: true,
            ),
          ],
        ),
    ],
  );
}
