import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../data/demo_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/map_widgets.dart';
import '../widgets/ontime_logo.dart';
import '../widgets/route_badge.dart';
import '../widgets/sheet_handle.dart';
import '../widgets/status_chip.dart';

/// Screen 7 — Live tracking with glassmorphic bottom panel.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, required this.busId});
  final String busId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _repo = DemoRepository.instance;
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

          return Stack(
            children: [
              // Dark map
              buildMap(
                controller: _mapCtl,
                center: pos.location,
                zoom: 15.5,
                layers: [
                  const AppMapTiles(),
                  PolylineLayer(polylines: [
                    Polyline(
                      points: route.path.take(_findIndex(route, pos.location)).toList(),
                      strokeWidth: 4,
                      color: AppColors.routePassed,
                      pattern: const StrokePattern.dotted(),
                    ),
                  ]),
                  PolylineLayer(polylines: [
                    Polyline(
                      points: route.path.skip(_findIndex(route, pos.location)).toList(),
                      strokeWidth: 4,
                      color: AppColors.secondary,
                    ),
                  ]),
                  MarkerLayer(markers: [
                    ..._stopMarkers(route, pos),
                    Marker(
                      point: pos.location,
                      width: 56,
                      height: 56,
                      child: LiveBusMarker(heading: pos.headingDeg),
                    ),
                  ]),
                ],
              ),

              // Top app bar
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Row(
                  children: [
                    _GlassFab(
                      icon: Icons.menu,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: OnTimeLogo(size: OnTimeLogoSize.small),
                    ),
                    _GlassFab(icon: Icons.search, onPressed: () {}),
                  ],
                ),
              ),

              // Right side FABs
              Positioned(
                right: AppSpacing.lg,
                top: MediaQuery.of(context).padding.top + 72,
                child: Column(
                  children: [
                    _FilterFab(
                      icon: Icons.filter_list,
                      highlighted: true,
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FilterFab(icon: Icons.layers, onPressed: () {}),
                  ],
                ),
              ),

              // Glassmorphic bottom panel
              Positioned(
                bottom: 100,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.sheetRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest.withOpacity(0.70),
                        borderRadius: BorderRadius.circular(AppSpacing.sheetRadius),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x99000000), blurRadius: 48, offset: Offset(0, -8)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SheetHandle(),

                          // Header row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'LIVE TRACKING',
                                            style: GoogleFonts.manrope(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.secondary,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Bus ${bus.number.split('-').first}',
                                      style: AppTypography.headline(28).copyWith(color: AppColors.primaryFixedDim),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${route.name} • ${route.destination}',
                                      style: GoogleFonts.manrope(fontSize: 13, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  RichText(
                                    text: TextSpan(children: [
                                      TextSpan(
                                        text: '${pos.etaMinutes} ',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.secondary,
                                          letterSpacing: -2,
                                          height: 1,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'mins',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.secondary.withOpacity(0.7),
                                        ),
                                      ),
                                    ]),
                                  ),
                                  Text(
                                    'ESTIMATED ARRIVAL',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Stats row
                          Row(
                            children: [
                              Expanded(child: _StatTile(icon: Icons.person, label: 'DRIVER', value: bus.driverName)),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: _StatTile(icon: Icons.speed, label: 'SPEED', value: '${pos.speedKmh.toStringAsFixed(0)}km/h')),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: _StatTile(icon: Icons.groups, label: 'LOAD', value: '${pos.occupancyPct}% Full')),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Subscribe button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryFixedDim],
                                ),
                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Subscribed to updates')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: AppColors.onPrimary,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'SUBSCRIBE TO UPDATES',
                                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, letterSpacing: 1),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    const Icon(Icons.notifications_active, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _findIndex(BusRoute r, LatLng p) {
    for (var i = 0; i < r.path.length; i++) {
      if (r.path[i].latitude == p.latitude && r.path[i].longitude == p.longitude) return i;
    }
    return 0;
  }

  List<Marker> _stopMarkers(BusRoute route, BusPosition pos) {
    return List.generate(route.stopIds.length, (i) {
      final stop = _repo.stopById(route.stopIds[i]);
      final passed = i < pos.nextStopIndex;
      return Marker(
        point: stop.location,
        width: 24,
        height: 24,
        child: StopMarker(passed: passed),
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _GlassFab extends StatelessWidget {
  const _GlassFab({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _FilterFab extends StatelessWidget {
  const _FilterFab({required this.icon, this.highlighted = false, required this.onPressed});
  final IconData icon;
  final bool highlighted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primaryContainer : AppColors.surfaceContainerHigh.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12)],
        ),
        child: Icon(icon, color: highlighted ? AppColors.primary : AppColors.onSurface, size: 24),
      ),
    );
  }
}
