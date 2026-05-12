import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../data/api_repository.dart';
import '../data/models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/map_widgets.dart';
import 'live_tracking_screen.dart';

/// Full live map — shows ALL buses from the WebSocket stream and REST snapshot.
/// Mirrors the web app's tracking page: real-time positions via wss://api.on-time.live/v1/live.
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with TickerProviderStateMixin {
  final _repo = ApiRepository.instance;
  final _mapCtl = MapController();

  // busId → latest live position (raw from WebSocket)
  final Map<String, BusLocation> _busPositions = {};
  // busId → smoothly animated display position
  final Map<String, _BusAnim> _busAnims = {};

  // busId → static bus info (fleet code, route id, etc.)
  Map<String, Bus> _staticBuses = {};

  StreamSubscription<BusLocation>? _wsSub;
  bool _wsConnected = false;
  bool _loading = true;

  // Selected bus for info panel
  String? _selectedBusId;

  // Connection status
  String _connectionStatus = 'Connecting…';

  // Default center: Colombo, Sri Lanka
  final _colombo = const LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Load static bus info (fleet codes, routes) from REST
    try {
      final buses = await _repo.getLiveBuses();
      if (mounted) {
        setState(() {
          _staticBuses = {for (final b in buses) b.id: b};
        });
      }
    } catch (_) {}

    // 2. Seed from REST /buses/live (may have lat/lng if driver is active)
    try {
      final raw = await ApiService.instance.getLiveBuses();
      for (final b in raw) {
        final rawLat = b['latitude'];
        final rawLng = b['longitude'];
        if (rawLat == null || rawLng == null) continue;
        final lat = (rawLat as num).toDouble();
        final lng = (rawLng as num).toDouble();
        if (lat == 0 && lng == 0) continue;

        final busId = b['id'].toString();
        _busPositions[busId] = BusLocation(
          busId: busId,
          fleetCode: b['fleet_code']?.toString() ?? '',
          routeId: b['route_id']?.toString() ?? '',
          lat: lat,
          lng: lng,
          speed: 0,
          heading: 0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          occupancy: 'low',
          occupancyPct: 25,
          status: b['status']?.toString() ?? 'active',
          driverName: b['fleet_code']?.toString() ?? '',
          eta: 0,
        );
      }
    } catch (_) {}

    // 3. Subscribe to WebSocket for real-time updates
    _wsSub = _repo.streamAllBuses().listen(
      (loc) {
        if (!mounted) return;
        if (loc.busId.isEmpty || loc.lat == 0 && loc.lng == 0) return;

        final newLatLng = LatLng(loc.lat, loc.lng);
        final anim = _busAnims[loc.busId];

        if (anim == null) {
          // First update for this bus — create its tween controller
          final ctrl = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 900),
          );
          final ba = _BusAnim(
            controller: ctrl,
            from: newLatLng,
            to: newLatLng,
            current: newLatLng,
            fromHeading: loc.heading,
            toHeading: loc.heading,
            currentHeading: loc.heading,
          );
          ctrl.addListener(() {
            if (!mounted) return;
            final t = ctrl.value;
            final a = _busAnims[loc.busId];
            if (a == null) return;
            final lat = a.from.latitude  + (a.to.latitude  - a.from.latitude)  * t;
            final lng = a.from.longitude + (a.to.longitude - a.from.longitude) * t;
            var dH = a.toHeading - a.fromHeading;
            if (dH >  180) dH -= 360;
            if (dH < -180) dH += 360;
            _busAnims[loc.busId] = a.copyWith(
              current: LatLng(lat, lng),
              currentHeading: a.fromHeading + dH * t,
            );
            if (mounted) setState(() {});
          });
          _busAnims[loc.busId] = ba;
        } else {
          // Subsequent update — retarget the tween from current animated pos
          final updated = anim.copyWith(
            from: anim.current,
            to: newLatLng,
            fromHeading: anim.currentHeading,
            toHeading: loc.heading,
          );
          _busAnims[loc.busId] = updated;
          updated.controller
            ..stop()
            ..forward(from: 0);
        }

        setState(() {
          _wsConnected = true;
          _connectionStatus = 'Live';
          _busPositions[loc.busId] = loc;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _connectionStatus = 'Reconnecting…');
      },
      onDone: () {
        if (mounted) setState(() => _connectionStatus = 'Disconnected');
      },
    );

    if (mounted) {
      setState(() => _loading = false);
      // Give a moment, then transition status
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && !_wsConnected) {
          setState(() => _connectionStatus = 'Waiting for data…');
        }
      });
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    for (final a in _busAnims.values) {
      a.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buses = _busPositions.values.toList();
    final selected =
        _selectedBusId != null ? _busPositions[_selectedBusId] : null;
    final selectedStatic = _selectedBusId != null
        ? (_staticBuses[_selectedBusId] ??
            _staticBuses.values
                .cast<Bus?>()
                .firstWhere(
                  (b) =>
                      b?.number.toUpperCase() ==
                      _selectedBusId?.toUpperCase(),
                  orElse: () => null,
                ))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          Positioned.fill(
            child: buildMap(
              controller: _mapCtl,
              center: buses.isNotEmpty
                  ? LatLng(buses.first.lat, buses.first.lng)
                  : _colombo,
              zoom: 13,
              layers: [
                const AppMapTiles(),
                // Route polylines (from cached repo data)
                PolylineLayer(
                  polylines: _repo.routes
                      .map((route) => Polyline(
                            points: route.path,
                            strokeWidth: 3,
                            color: AppColors.primary.withOpacity(0.6),
                          ))
                      .toList(),
                ),
                // Live bus markers
                MarkerLayer(
                  markers: buses.map((loc) {
                    final anim = _busAnims[loc.busId];
                    final displayPos = anim?.current ?? LatLng(loc.lat, loc.lng);
                    final displayHeading = anim?.currentHeading ?? loc.heading;
                    final isSelected = loc.busId == _selectedBusId;
                    return Marker(
                      point: displayPos,
                      width: isSelected ? 56 : 48,
                      height: isSelected ? 56 : 48,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBusId =
                                _selectedBusId == loc.busId ? null : loc.busId;
                          });
                          if (_selectedBusId != null) {
                            _mapCtl.move(displayPos, _mapCtl.camera.zoom);
                          }
                        },
                        child: _BusMapMarker(
                          loc: loc.copyWith(),
                          isSelected: isSelected,
                          heading: displayHeading,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // User location
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _repo.userLocation,
                      width: 48,
                      height: 48,
                      child: const UserLocationMarker(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Top bar ───────────────────────────────────────────────────────
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
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: glassPanelDecoration(
                    radius: AppSpacing.buttonRadius,
                  ),
                  child: Row(
                    children: [
                      // Live indicator dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _wsConnected
                              ? AppColors.success
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Bus Map',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              _wsConnected
                                  ? '${buses.length} bus${buses.length == 1 ? '' : 'es'} live'
                                  : _connectionStatus,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _wsConnected
                                    ? AppColors.success
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Re-center button
                      if (buses.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.center_focus_strong),
                          color: AppColors.primary,
                          tooltip: 'Center on buses',
                          onPressed: () {
                            final first = buses.first;
                            _mapCtl.move(
                              LatLng(first.lat, first.lng),
                              14,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Empty state ────────────────────────────────────────────────────
          if (!_loading && buses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: glassPanelDecoration(
                          radius: AppSpacing.cardRadius),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_bus_outlined,
                            size: 64,
                            color: AppColors.outline.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No Live Buses',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Buses will appear here once drivers\nstart their trips and GPS data arrives.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Selected bus panel ─────────────────────────────────────────────
          if (selected != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  MediaQuery.of(context).padding.bottom + 80,
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: glassPanelDecoration(
                          radius: AppSpacing.cardRadius),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header row
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.md),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.directions_bus,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selected.fleetCode.isNotEmpty
                                            ? 'Bus ${selected.fleetCode}'
                                            : 'Bus ${selected.busId}',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      if (selectedStatic?.routeId.isNotEmpty ?? false)
                                        Text(
                                          'Route ${_repo.routeById(selectedStatic!.routeId).code}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (selected.status == 'delayed' ||
                                            selected.status == 'DELAYED')
                                        ? AppColors.errorBright
                                            .withOpacity(0.12)
                                        : AppColors.success.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: (selected.status ==
                                                      'delayed' ||
                                                  selected.status ==
                                                      'DELAYED')
                                              ? AppColors.errorBright
                                              : AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (selected.status == 'delayed' ||
                                                selected.status == 'DELAYED')
                                            ? 'Delayed'
                                            : 'Active',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: (selected.status ==
                                                      'delayed' ||
                                                  selected.status ==
                                                      'DELAYED')
                                              ? AppColors.errorBright
                                              : AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Stats
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.speed,
                                    label: 'Speed',
                                    value:
                                        '${selected.speed.toStringAsFixed(0)} km/h',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.groups_outlined,
                                    label: 'Load',
                                    value: '${selected.occupancyPct}%',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.schedule,
                                    label: 'ETA',
                                    value: selected.eta > 0
                                        ? '${selected.eta} min'
                                        : '—',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Track button
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => LiveTrackingScreen(
                                      busId: selected.busId,
                                      routeDbId: selectedStatic?.routeId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.near_me, size: 18),
                              label: const Text('Track This Bus'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Per-bus animation state — immutable value object.
class _BusAnim {
  _BusAnim({
    required this.controller,
    required this.from,
    required this.to,
    required this.current,
    required this.fromHeading,
    required this.toHeading,
    required this.currentHeading,
  });

  final AnimationController controller;
  final LatLng from;
  final LatLng to;
  final LatLng current;
  final double fromHeading;
  final double toHeading;
  final double currentHeading;

  _BusAnim copyWith({
    LatLng? from,
    LatLng? to,
    LatLng? current,
    double? fromHeading,
    double? toHeading,
    double? currentHeading,
  }) =>
      _BusAnim(
        controller: controller,
        from: from ?? this.from,
        to: to ?? this.to,
        current: current ?? this.current,
        fromHeading: fromHeading ?? this.fromHeading,
        toHeading: toHeading ?? this.toHeading,
        currentHeading: currentHeading ?? this.currentHeading,
      );
}

class _BusMapMarker extends StatefulWidget {
  const _BusMapMarker({
    required this.loc,
    required this.isSelected,
    this.heading,
  });
  final BusLocation loc;
  final bool isSelected;
  /// Overrides loc.heading with the smoothly interpolated value.
  final double? heading;

  @override
  State<_BusMapMarker> createState() => _BusMapMarkerState();
}

class _BusMapMarkerState extends State<_BusMapMarker>
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
            if (widget.isSelected)
              Opacity(
                opacity: (1 - _c.value).clamp(0.0, 0.5),
                child: Container(
                  width: 56 * _c.value,
                  height: 56 * _c.value,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Transform.rotate(
              angle: (widget.heading ?? widget.loc.heading) * 3.14159265359 / 180,
              child: Container(
                width: widget.isSelected ? 48 : 40,
                height: widget.isSelected ? 48 : 40,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: widget.isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: widget.isSelected ? 24 : 20,
                ),
              ),
            ),
            // Fleet code label
            if (widget.loc.fleetCode.isNotEmpty)
              Positioned(
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.loc.fleetCode,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.onSurface,
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
