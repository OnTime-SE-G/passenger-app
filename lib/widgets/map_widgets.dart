import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

/// Dark-themed CARTO tiles (Dark Matter).
class AppMapTiles extends StatelessWidget {
  const AppMapTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate:
          'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      retinaMode: MediaQuery.of(context).devicePixelRatio > 1.5,
      userAgentPackageName: 'com.ontime.passenger_app',
      subdomains: const ['a', 'b', 'c', 'd'],
    );
  }
}

/// Pulsing cyan dot for user location.
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
                  color: AppColors.secondary.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.4),
                    blurRadius: 15,
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

/// Bus stop markers on the map.
class StopMarker extends StatelessWidget {
  const StopMarker({super.key, this.selected = false, this.passed = false});
  final bool selected;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final bg = passed
        ? AppColors.routePassed
        : selected
            ? AppColors.secondary
            : AppColors.surfaceBright;
    final border = passed ? AppColors.routePassed : AppColors.secondary;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 3),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 8),
        ],
      ),
    );
  }
}

/// Glowing cyan bus marker with pulse ring.
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
              opacity: (1 - _c.value).clamp(0.0, 0.5),
              child: Container(
                width: 56 * _c.value,
                height: 56 * _c.value,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Quick helper to build a FlutterMap.
FlutterMap buildMap({
  required MapController controller,
  required LatLng center,
  double zoom = 15,
  required List<Widget> layers,
  bool interactive = true,
}) {
  return FlutterMap(
    mapController: controller,
    options: MapOptions(
      initialCenter: center,
      initialZoom: zoom,
      interactionOptions: InteractionOptions(
        flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
      ),
    ),
    children: layers,
  );
}
