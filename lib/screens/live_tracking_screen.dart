import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../data/api_repository.dart';
import '../data/demo_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Live tracking — Mapbox map + frosted route panel + stops list.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, required this.busId});
  final String busId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _apiRepo = ApiRepository.instance;
  final _demoRepo = DemoRepository.instance;

  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _passedLineManager;
  PolylineAnnotationManager? _aheadLineManager;
  CircleAnnotationManager? _stopCircleManager;
  CircleAnnotationManager? _busCircleManager;

  StreamSubscription<BusPosition>? _sub;
  BusPosition? _latest;

  late Bus _bus;
  BusRoute? _route;
  List<BusStop> _stops = [];
  bool _styleReady = false;

  @override
  void initState() {
    super.initState();
    _bus = _demoRepo.busById(widget.busId);
    _loadRouteData(_bus.routeId);
    _sub = _apiRepo.watchBus(widget.busId).listen((pos) {
      if (!mounted) return;
      setState(() => _latest = pos);
      _updateBusAnnotation(pos);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadRouteData(String routeId) async {
    try {
      final route = await _apiRepo.routeById(routeId);
      final allStops = await _apiRepo.stops;
      final routeStops = route.stopIds
          .map((id) => allStops.firstWhere(
                (s) => s.id == id,
                orElse: () => _demoRepo.stopById(id),
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _route = route;
        _stops = routeStops;
      });
      if (_styleReady) await _drawRouteAnnotations(route, routeStops, _latest?.nextStopIndex ?? 0);
    } catch (_) {
      if (!mounted) return;
      final route = _demoRepo.routeById(routeId);
      final stops = route.stopIds.map((id) => _demoRepo.stopById(id)).toList();
      setState(() {
        _route = route;
        _stops = stops;
      });
      if (_styleReady) await _drawRouteAnnotations(route, stops, _latest?.nextStopIndex ?? 0);
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    _styleReady = true;
    if (_mapboxMap == null) return;
    _passedLineManager = await _mapboxMap!.annotations.createPolylineAnnotationManager();
    _aheadLineManager = await _mapboxMap!.annotations.createPolylineAnnotationManager();
    _stopCircleManager = await _mapboxMap!.annotations.createCircleAnnotationManager();
    _busCircleManager = await _mapboxMap!.annotations.createCircleAnnotationManager();
    final route = _route;
    if (route != null) {
      await _drawRouteAnnotations(route, _stops, _latest?.nextStopIndex ?? 0);
    }
  }

  Future<void> _drawRouteAnnotations(BusRoute route, List<BusStop> stops, int nextIdx) async {
    if (_passedLineManager == null || !mounted) return;
    final pos = _latest ?? _demoRepo.snapshotFor(widget.busId);
    final snapIdx = _snapIndex(route, pos.location);

    await _passedLineManager!.deleteAll();
    if (snapIdx > 0 && route.path.length > 1) {
      await _passedLineManager!.create(PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: route.path.take(snapIdx + 1).map((p) => Position(p.longitude, p.latitude)).toList(),
        ),
        lineWidth: 4.0,
        lineColor: AppColors.routePassed.value,
      ));
    }

    await _aheadLineManager!.deleteAll();
    if (snapIdx < route.path.length - 1) {
      await _aheadLineManager!.create(PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: route.path.skip(snapIdx).map((p) => Position(p.longitude, p.latitude)).toList(),
        ),
        lineWidth: 5.0,
        lineColor: route.accentColor.value,
      ));
    }

    await _stopCircleManager!.deleteAll();
    if (stops.isNotEmpty) {
      await _stopCircleManager!.createMulti(
        List.generate(stops.length, (i) {
          final st = _legFor(i, nextIdx);
          return CircleAnnotationOptions(
            geometry: Point(coordinates: Position(stops[i].location.longitude, stops[i].location.latitude)),
            circleRadius: 6.0,
            circleColor: st == _StopLeg.passed
                ? AppColors.routePassed.value
                : st == _StopLeg.current
                    ? route.accentColor.value
                    : Colors.white.value,
            circleStrokeColor: st == _StopLeg.upcoming ? route.accentColor.value : Colors.white.value,
            circleStrokeWidth: 2.5,
          );
        }),
      );
    }
  }

  Future<void> _updateBusAnnotation(BusPosition pos) async {
    if (_busCircleManager == null || !mounted) return;
    await _busCircleManager!.deleteAll();
    await _busCircleManager!.create(CircleAnnotationOptions(
      geometry: Point(coordinates: Position(pos.location.longitude, pos.location.latitude)),
      circleRadius: 13.0,
      circleColor: AppColors.primary.value,
      circleStrokeColor: Colors.white.value,
      circleStrokeWidth: 3.0,
    ));
    final route = _route;
    if (route != null) await _drawRouteAnnotations(route, _stops, pos.nextStopIndex);
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(pos.location.longitude, pos.location.latitude)),
        zoom: 14.0,
      ),
      MapAnimationOptions(duration: 800),
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

  _StopLeg _legFor(int i, int nextIdx) {
    if (i < nextIdx) return _StopLeg.passed;
    if (i == nextIdx) return _StopLeg.current;
    return _StopLeg.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final route = _route ?? _demoRepo.routeById(_bus.routeId);
    final pos = _latest ?? _demoRepo.snapshotFor(widget.busId);
    final stops = _stops.isEmpty
        ? route.stopIds.map((id) => _demoRepo.stopById(id)).toList()
        : _stops;
    final delayed = pos.status == BusLiveStatus.delayed;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Mapbox map ───────────────────────────────────────────────────
          Positioned.fill(
            child: MapWidget(
              styleUri: MapboxStyles.STANDARD,
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(pos.location.longitude, pos.location.latitude)),
                zoom: 14.0,
              ),
              onMapCreated: (map) => _mapboxMap = map,
              onStyleLoadedListener: _onStyleLoaded,
            ),
          ),

          // ── Top chrome ──────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: glassPanelDecoration(radius: AppSpacing.buttonRadius),
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

          // ── Glass bottom panel ───────────────────────────────────────────
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.sheetRadius),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          decoration: glassPanelDecoration(radius: AppSpacing.sheetRadius),
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
                                        borderRadius: BorderRadius.circular(AppSpacing.md),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.directions_bus, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  text: delayed ? 'Delayed' : 'On Time',
                                                  style: TextStyle(
                                                    color: delayed ? AppColors.errorBright : AppColors.success,
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
                                            'Driver: ${_bus.driverName}',
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
                                    Expanded(child: _MiniStat(icon: Icons.schedule, label: 'ETA', value: '${pos.etaMinutes} min')),
                                    const SizedBox(width: 10),
                                    Expanded(child: _MiniStat(icon: Icons.speed, label: 'Speed', value: '${pos.speedKmh.toStringAsFixed(0)} km/h')),
                                    const SizedBox(width: 10),
                                    Expanded(child: _MiniStat(icon: Icons.groups_outlined, label: 'Load', value: '${pos.occupancyPct}%')),
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
                                ...List.generate(stops.length, (i) {
                                  final st = _legFor(i, pos.nextStopIndex);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _StopListTile(
                                      stopName: stops[i].name,
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
      ),
    );
  }
}

enum _StopLeg { passed, current, upcoming }

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onSurface)),
          Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StopListTile extends StatelessWidget {
  const _StopListTile({required this.stopName, required this.state, required this.accent});
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
        color: state == _StopLeg.current ? accent.withValues(alpha: 0.08) : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border(left: BorderSide(color: state == _StopLeg.current ? accent : Colors.transparent, width: 3)),
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
              state == _StopLeg.passed ? Icons.check : Icons.radio_button_unchecked,
              size: 14,
              color: state == _StopLeg.upcoming ? AppColors.onSurfaceVariant : Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stopName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onSurface.withValues(alpha: state == _StopLeg.passed ? 0.55 : 1))),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.onSurfaceVariant)),
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
      case 'r1': return const Color(0xFF2563EB);
      case 'r2': return const Color(0xFF7C3AED);
      case 'r3': return const Color(0xFF0891B2);
      case 'r4': return const Color(0xFFEA580C);
      default:   return AppColors.primaryContainer;
    }
  }
}
