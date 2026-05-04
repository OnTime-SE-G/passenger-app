import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../data/api_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/map_widgets.dart';

/// Live tracking — Voyager map + frosted route panel + stops list.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, required this.busId});
  final String busId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _repo = ApiRepository.instance;
  final _mapCtl = MapController();
  late final Stream<BusPosition> _stream;
  BusPosition? _latest;

  @override
  void initState() {
    super.initState();
    _stream = _repo.watchBus(widget.busId).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final bus = _repo.busById(widget.busId);
    final route = _repo.routeById(bus.routeId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<BusPosition>(
        stream: _stream,
        builder: (context, snap) {
          final pos = snap.data ?? _latest ?? _repo.snapshotFor(widget.busId);
          _latest = pos;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !snap.hasData) return;
            try {
              _mapCtl.move(pos.location, _mapCtl.camera.zoom);
            } catch (_) {}
          });

          final delayed = pos.status == BusLiveStatus.delayed;

          return Stack(
            children: [
              Positioned.fill(
                child: buildMap(
                  controller: _mapCtl,
                  center: pos.location,
                  zoom: 14,
                  layers: [
                    const AppMapTiles(),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: route.path
                              .take(_snapIndex(route, pos.location))
                              .toList(),
                          strokeWidth: 4,
                          color: AppColors.routePassed,
                          pattern: const StrokePattern.dotted(),
                        ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: route.path
                              .skip(_snapIndex(route, pos.location))
                              .toList(),
                          strokeWidth: 5,
                          color: route.accentColor,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        ...List.generate(route.stopIds.length, (i) {
                          final stop = _repo.stopById(route.stopIds[i]);
                          final st = _stopState(i, pos.nextStopIndex);
                          return Marker(
                            point: stop.location,
                            width: 18,
                            height: 18,
                            child: _StopDot(state: st, accent: route.accentColor),
                          );
                        }),
                        Marker(
                          point: pos.location,
                          width: 48,
                          height: 48,
                          child: LiveBusMarker(heading: pos.headingDeg),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Top chrome
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: glassPanelDecoration(
                        radius: AppSpacing.buttonRadius,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: AppColors.onSurface,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Text(
                              'Live Tracking',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Glass panel — expandable bottom sheet on mobile, fixed width on web.
              Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.35,
                    minChildSize: 0.15,
                    maxChildSize: 0.85,
                    builder: (context, scrollController) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.sheetRadius)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              decoration: glassPanelDecoration(
                                radius: AppSpacing.sheetRadius,
                              ),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: route.accentColor,
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.md),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.directions_bus,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                          children: [
                                            TextSpan(text: 'Route ${route.code} · '),
                                            TextSpan(
                                              text: delayed
                                                  ? 'Delayed'
                                                  : 'On Time',
                                              style: TextStyle(
                                                color: delayed
                                                    ? AppColors.errorBright
                                                    : AppColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        route.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Driver: ${bus.driverName}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStat(
                                    icon: Icons.schedule,
                                    label: 'ETA',
                                    value: '${pos.etaMinutes} min',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _MiniStat(
                                    icon: Icons.speed,
                                    label: 'Speed',
                                    value:
                                        '${pos.speedKmh.toStringAsFixed(0)} km/h',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _MiniStat(
                                    icon: Icons.groups_outlined,
                                    label: 'Load',
                                    value: '${pos.occupancyPct}%',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'ROUTE STOPS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...List.generate(route.stopIds.length, (i) {
                              final stop = _repo.stopById(route.stopIds[i]);
                              final st = _stopState(i, pos.nextStopIndex);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _StopListTile(
                                  stopName: stop.name,
                                  state: st,
                                  accent: route.accentColor,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
            ],
          );
        },
      ),
    );
  }

  int _snapIndex(BusRoute r, LatLng p) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < r.path.length; i++) {
      final d = _dist(r.path[i], p);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  double _dist(LatLng a, LatLng b) {
    final dx = a.longitude - b.longitude;
    final dy = a.latitude - b.latitude;
    return dx * dx + dy * dy;
  }

  _StopLeg _stopState(int i, int nextIdx) {
    if (i < nextIdx) return _StopLeg.passed;
    if (i == nextIdx) return _StopLeg.current;
    return _StopLeg.upcoming;
  }
}

enum _StopLeg { passed, current, upcoming }

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopDot extends StatelessWidget {
  const _StopDot({required this.state, required this.accent});
  final _StopLeg state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bg = state == _StopLeg.passed
        ? AppColors.routePassed
        : state == _StopLeg.current
            ? accent
            : Colors.white;
    final border = state == _StopLeg.upcoming ? accent : Colors.white;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
        ],
      ),
    );
  }
}

class _StopListTile extends StatelessWidget {
  const _StopListTile({
    required this.stopName,
    required this.state,
    required this.accent,
  });

  final String stopName;
  final _StopLeg state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (state) {
      _StopLeg.passed => 'Passed',
      _StopLeg.current => 'Next stop',
      _StopLeg.upcoming => 'Scheduled',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: state == _StopLeg.current
            ? accent.withOpacity(0.08)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border(
          left: BorderSide(
            color: state == _StopLeg.current ? accent : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: state == _StopLeg.passed
                  ? AppColors.routePassed
                  : state == _StopLeg.current
                      ? accent
                      : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              state == _StopLeg.passed
                  ? Icons.check
                  : Icons.radio_button_unchecked,
              size: 14,
              color: state == _StopLeg.upcoming
                  ? AppColors.onSurfaceVariant
                  : Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stopName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.onSurface.withOpacity(
                      state == _StopLeg.passed ? 0.55 : 1,
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension BusRouteTrackingColors on BusRoute {
  Color get accentColor {
    switch (id) {
      case 'r1':
        return const Color(0xFF2563EB);
      case 'r2':
        return const Color(0xFF7C3AED);
      case 'r3':
        return const Color(0xFF0891B2);
      case 'r4':
        return const Color(0xFFEA580C);
      default:
        return AppColors.primaryContainer;
    }
  }
}
