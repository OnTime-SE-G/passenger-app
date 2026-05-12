import 'dart:async';
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
  const LiveTrackingScreen({
    super.key,
    required this.busId,
    /// Matches web `/tracking?routeDbId=` — improves REST + WS filtering when set.
    this.routeDbId,
  });
  final String busId;
  final String? routeDbId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  final _repo = ApiRepository.instance;
  final _mapCtl = MapController();
  late final Stream<BusPosition> _stream;
  StreamSubscription<BusPosition>? _sub;

  // ── Smooth position interpolation ─────────────────────────────────────────
  // We keep two LatLng refs and tween between them so the marker glides
  // continuously instead of snapping every WebSocket interval (~1-2 s).
  late AnimationController _posAnim;
  LatLng _fromLatLng = const LatLng(0, 0);
  LatLng _toLatLng   = const LatLng(0, 0);
  // Current interpolated position driven by the animation.
  LatLng _animatedLatLng = const LatLng(0, 0);

  // Heading interpolation (degrees)
  double _fromHeading = 0;
  double _toHeading   = 0;
  double _animatedHeading = 0;

  BusPosition? _latest;
  bool _hasLiveData = false;

  @override
  void initState() {
    super.initState();

    // Tween duration is slightly shorter than the WS interval so the marker
    // always reaches the target before the next update arrives.
    _posAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _posAnim.addListener(() {
      if (!mounted) return;
      final t = _posAnim.value;
      final lat =
          _fromLatLng.latitude  + (_toLatLng.latitude  - _fromLatLng.latitude)  * t;
      final lng =
          _fromLatLng.longitude + (_toLatLng.longitude - _fromLatLng.longitude) * t;

      // Shortest-arc heading lerp
      var dH = _toHeading - _fromHeading;
      if (dH >  180) dH -= 360;
      if (dH < -180) dH += 360;
      _animatedHeading = _fromHeading + dH * t;

      _animatedLatLng = LatLng(lat, lng);

      // Move map camera smoothly with the marker
      try { _mapCtl.move(_animatedLatLng, _mapCtl.camera.zoom); } catch (_) {}
      setState(() {});
    });

    _stream = _repo
        .watchBus(widget.busId, routeDbId: widget.routeDbId)
        .asBroadcastStream();

    _sub = _stream.listen((pos) {
      if (!mounted) return;

      final newLatLng = pos.location;
      final isReal = newLatLng.latitude != 0 && newLatLng.longitude != 0;

      if (isReal) {
        // Seed from & to on very first real update
        if (!_hasLiveData) {
          _fromLatLng     = newLatLng;
          _animatedLatLng = newLatLng;
          _fromHeading    = pos.headingDeg;
          _animatedHeading = pos.headingDeg;
          _hasLiveData = true;
        } else {
          _fromLatLng  = _animatedLatLng; // start from where we are NOW
          _fromHeading = _animatedHeading;
        }
        _toLatLng   = newLatLng;
        _toHeading  = pos.headingDeg;

        // Restart tween toward new target
        _posAnim
          ..stop()
          ..forward(from: 0);
      }

      setState(() { _latest = pos; });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _posAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bus = _repo.busById(widget.busId);
    final route = _repo.routeById(bus.routeId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Builder(
        builder: (context) {
          final pos = _latest ?? _repo.snapshotFor(widget.busId);
          // Use the interpolated position for the marker; fall back to latest
          // from REST snapshot when WebSocket hasn't arrived yet.
          final markerPos = _hasLiveData ? _animatedLatLng : pos.location;
          final markerHeading = _hasLiveData ? _animatedHeading : pos.headingDeg;
          final delayed = pos.status == BusLiveStatus.delayed;

          return Stack(
            children: [
              Positioned.fill(
                child: buildMap(
                  controller: _mapCtl,
                  center: markerPos,
                  zoom: 14,
                  layers: [
                    const AppMapTiles(),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: route.path
                              .take(_snapIndex(route, markerPos))
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
                              .skip(_snapIndex(route, markerPos))
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
                          point: markerPos,
                          width: 48,
                          height: 48,
                          child: LiveBusMarker(heading: markerHeading),
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
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          // Live / waiting badge
                          Container(
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _hasLiveData
                                  ? AppColors.success.withOpacity(0.12)
                                  : Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _hasLiveData
                                        ? AppColors.success
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _hasLiveData ? 'Live' : 'Syncing…',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _hasLiveData
                                        ? AppColors.success
                                        : Colors.orange,
                                  ),
                                ),
                              ],
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
                                          style: GoogleFonts.inter(
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
                                        style: GoogleFonts.inter(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(builder: (_) {
                                        final name = pos.driverDisplay.isNotEmpty
                                            ? pos.driverDisplay
                                            : bus.driverName;
                                        if (name.isEmpty) return const SizedBox.shrink();
                                        return Text(
                                          'Driver: $name',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        );
                                      }),
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
                                    value: pos.etaMinutes > 0
                                        ? '${pos.etaMinutes} min'
                                        : '— min',
                                    dimmed: pos.etaMinutes == 0,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _MiniStat(
                                    icon: Icons.speed,
                                    label: 'Speed',
                                    value: pos.speedKmh > 0
                                        ? '${pos.speedKmh.toStringAsFixed(0)} km/h'
                                        : '— km/h',
                                    dimmed: pos.speedKmh == 0,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _MiniStat(
                                    icon: Icons.groups_outlined,
                                    label: 'Load',
                                    value: pos.occupancyPct > 0
                                        ? '${pos.occupancyPct}%'
                                        : '—%',
                                    dimmed: pos.occupancyPct == 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'ROUTE STOPS',
                              style: GoogleFonts.inter(
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
    this.dimmed = false,
  });

  final IconData icon;
  final String label;
  final String value;
  /// When true, renders the value in a muted style — signals "no data yet".
  final bool dimmed;

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
          Icon(icon,
              size: 16,
              color: dimmed
                  ? AppColors.onSurfaceVariant.withOpacity(0.5)
                  : AppColors.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: dimmed ? FontWeight.w500 : FontWeight.w700,
              fontStyle: dimmed ? FontStyle.italic : FontStyle.normal,
              fontSize: 15,
              color: dimmed
                  ? AppColors.onSurfaceVariant.withOpacity(0.6)
                  : AppColors.onSurface,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.onSurface.withOpacity(
                      state == _StopLeg.passed ? 0.55 : 1,
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
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
