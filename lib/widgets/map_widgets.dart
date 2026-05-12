import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

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
    if (token.isEmpty) {
      return TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.ontime.passenger_app',
      );
    }
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

/// Beautiful SVG-quality live bus marker.
/// Draws a top-down bus silhouette — forward (nose) points UP (north) at heading=0.
/// Heading rotation is applied internally.
class LiveBusMarker extends StatefulWidget {
  const LiveBusMarker({
    super.key,
    this.heading = 0,
    this.color,
    this.selected = false,
    this.fleetCode,
  });
  final double heading;
  final Color? color;
  final bool selected;
  final String? fleetCode;

  @override
  State<LiveBusMarker> createState() => _LiveBusMarkerState();
}

class _LiveBusMarkerState extends State<LiveBusMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primaryContainer;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: widget.heading * 3.14159265359 / 180,
            child: CustomPaint(
              size: const Size(56, 56),
              painter: _BusBodyPainter(
                color: color,
                pulseT: _pulse.value,
                selected: widget.selected,
              ),
            ),
          ),
          if (widget.fleetCode != null && widget.fleetCode!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                widget.fleetCode!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter that draws a beautiful top-down bus silhouette.
class _BusBodyPainter extends CustomPainter {
  const _BusBodyPainter({
    required this.color,
    required this.pulseT,
    required this.selected,
  });

  final Color color;
  final double pulseT;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Pulsing halo ─────────────────────────────────────────────────────────
    final haloR = 18.0 + 14.0 * pulseT;
    canvas.drawCircle(
      Offset(cx, cy),
      haloR,
      Paint()..color = color.withOpacity((0.5 * (1 - pulseT)).clamp(0.0, 0.5)),
    );

    // ── Bus body geometry ─────────────────────────────────────────────────────
    // Nose at TOP (y-min). Rear at BOTTOM (y-max). Horizontally centered.
    final bw = size.width * 0.50;   // ~28 px
    final bh = size.height * 0.70;  // ~39 px
    final bl = cx - bw / 2;
    final bt = cy - bh / 2;
    final br = bl + bw;
    final bb = bt + bh;
    final rMain = Radius.circular(bw * 0.36);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(bl, bt, br, bb),
      rMain,
    );

    // Drop shadow
    canvas.drawRRect(
      bodyRect.inflate(1).shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main body fill
    canvas.drawRRect(bodyRect, Paint()..color = color);

    // ── Roof strip — front 28 % of body, darker shade ────────────────────────
    final roofH = bh * 0.28;
    final roofColor = Color.lerp(color, Colors.black, 0.22)!;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        bl, bt, br, bt + roofH,
        topLeft: rMain,
        topRight: rMain,
      ),
      Paint()..color = roofColor,
    );

    // Windscreen highlight inside roof
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bl + 4, bt + 4, bw - 8, roofH * 0.60),
        Radius.circular(bw * 0.20),
      ),
      Paint()..color = Colors.white.withOpacity(0.20),
    );

    // ── Side windows (2 rows, 1 window each side) ────────────────────────────
    final ww = bw * 0.29;
    final wh = bh * 0.17;
    const wr = Radius.circular(2.5);
    final windowPaint = Paint()..color = Colors.white.withOpacity(0.88);
    final wy1 = bt + roofH + 5;
    final wy2 = wy1 + wh + 5;
    for (final wy in [wy1, wy2]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bl + 3, wy, ww, wh), wr),
        windowPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(br - 3 - ww, wy, ww, wh), wr),
        windowPaint,
      );
    }

    // ── Headlights ────────────────────────────────────────────────────────────
    final hlPaint = Paint()..color = const Color(0xFFFFF176);
    canvas.drawCircle(Offset(bl + 5, bt + 5), 2.5, hlPaint);
    canvas.drawCircle(Offset(br - 5, bt + 5), 2.5, hlPaint);

    // ── White border ──────────────────────────────────────────────────────────
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = Colors.white.withOpacity(selected ? 1.0 : 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.5 : 2.0,
    );

    // ── Direction arrow (triangular nose) ────────────────────────────────────
    final aw = bw * 0.42;
    final arrowPath = Path()
      ..moveTo(cx, bt - 6)
      ..lineTo(cx - aw / 2, bt + 2)
      ..lineTo(cx + aw / 2, bt + 2)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BusBodyPainter old) =>
      old.pulseT != pulseT || old.color != color || old.selected != selected;
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
