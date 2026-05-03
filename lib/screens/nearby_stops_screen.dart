import 'dart:async';

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
import '../theme/app_typography.dart';
import '../widgets/app_card.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/route_badge.dart';
import '../widgets/sheet_handle.dart';
import 'stop_details_screen.dart';

/// Nearby stops — Mapbox map + draggable sheet over light chrome.
class NearbyStopsScreen extends StatefulWidget {
  const NearbyStopsScreen({super.key, this.destinationQuery});
  final String? destinationQuery;

  @override
  State<NearbyStopsScreen> createState() => _NearbyStopsScreenState();
}

class _NearbyStopsScreenState extends State<NearbyStopsScreen> {
  final _apiRepo = ApiRepository.instance;
  final _demoRepo = DemoRepository.instance;

  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _routeLineManager;
  CircleAnnotationManager? _stopCircleManager;
  CircleAnnotationManager? _userCircleManager;

  final _searchCtl = TextEditingController();
  BusStop? _selected;
  String _searchQuery = '';
  double _zoom = 15.0;

  List<({BusStop stop, double meters})> _nearby = [];
  List<BusRoute> _routes = [];
  bool _styleReady = false;

  static const _routeColors = [
    Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFF0891B2), Color(0xFFEA580C),
  ];

  LatLng get _userLocation => _demoRepo.userLocation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final nearby = await _apiRepo.nearbyStops(_userLocation);
      final routes = await _apiRepo.routes;
      if (!mounted) return;
      setState(() {
        _nearby = nearby;
        _routes = routes;
        if (nearby.isNotEmpty) _selected = nearby.first.stop;
      });
      if (_styleReady) await _drawAnnotations();
    } catch (_) {
      if (!mounted) return;
      final nearby = _demoRepo.nearbyStops(_userLocation);
      setState(() {
        _nearby = nearby;
        _routes = _demoRepo.routes;
        if (nearby.isNotEmpty) _selected = nearby.first.stop;
      });
      if (_styleReady) await _drawAnnotations();
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    _styleReady = true;
    if (_mapboxMap == null) return;
    _routeLineManager = await _mapboxMap!.annotations.createPolylineAnnotationManager();
    _stopCircleManager = await _mapboxMap!.annotations.createCircleAnnotationManager();
    _userCircleManager = await _mapboxMap!.annotations.createCircleAnnotationManager();
    if (_nearby.isNotEmpty) await _drawAnnotations();
  }

  Future<void> _drawAnnotations() async {
    if (_routeLineManager == null) return;
    // Route polylines
    await _routeLineManager!.deleteAll();
    if (_routes.isNotEmpty) {
      await _routeLineManager!.createMulti(
        List.generate(_routes.length, (i) => PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: _routes[i].path.map((p) => Position(p.longitude, p.latitude)).toList(),
          ),
          lineWidth: 3.5,
          lineColor: _routeColors[i % _routeColors.length].withValues(alpha: 0.7).toARGB32(),
        )),
      );
    }
    // Stop circles
    await _stopCircleManager!.deleteAll();
    if (_nearby.isNotEmpty) {
      await _stopCircleManager!.createMulti(_nearby.map((e) {
        final isSelected = _selected?.id == e.stop.id;
        return CircleAnnotationOptions(
          geometry: Point(coordinates: Position(e.stop.location.longitude, e.stop.location.latitude)),
          circleRadius: isSelected ? 9.0 : 6.0,
          circleColor: isSelected ? AppColors.primary.toARGB32() : Colors.white.toARGB32(),
          circleStrokeColor: AppColors.primary.toARGB32(),
          circleStrokeWidth: isSelected ? 3.0 : 2.0,
        );
      }).toList());
    }
    // User location
    await _userCircleManager!.deleteAll();
    await _userCircleManager!.create(CircleAnnotationOptions(
      geometry: Point(coordinates: Position(_userLocation.longitude, _userLocation.latitude)),
      circleRadius: 8.0,
      circleColor: AppColors.primary.toARGB32(),
      circleStrokeColor: Colors.white.toARGB32(),
      circleStrokeWidth: 3.0,
    ));
  }

  void _select(BusStop s) {
    setState(() => _selected = s);
    _mapboxMap?.flyTo(
      CameraOptions(center: Point(coordinates: Position(s.location.longitude, s.location.latitude)), zoom: 16.0),
      MapAnimationOptions(duration: 500),
    );
    if (_styleReady) _drawAnnotations();
  }

  void _zoomIn() {
    _zoom = (_zoom + 1).clamp(1.0, 22.0);
    _mapboxMap?.flyTo(CameraOptions(zoom: _zoom), MapAnimationOptions(duration: 300));
  }

  void _zoomOut() {
    _zoom = (_zoom - 1).clamp(1.0, 22.0);
    _mapboxMap?.flyTo(CameraOptions(zoom: _zoom), MapAnimationOptions(duration: 300));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _nearby
        : _nearby.where((e) => e.stop.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          Positioned.fill(
            child: MapWidget(
              styleUri: MapboxStyles.STANDARD,
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(_userLocation.longitude, _userLocation.latitude)),
                zoom: _zoom,
              ),
              onMapCreated: (map) => _mapboxMap = map,
              onStyleLoadedListener: _onStyleLoaded,
            ),
          ),

          // ── Top search bar ───────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Container(
              decoration: glassPanelDecoration(radius: AppSpacing.buttonRadius),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                    )
                  else
                    const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search bus stops…',
                        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: AppColors.onSurfaceVariant,
                                onPressed: () {
                                  _searchCtl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  GlobalHeaderActions(onRefresh: _loadData, onNotifications: () {}, onProfile: () {}),
                ],
              ),
            ),
          ),

          // ── Zoom FABs ───────────────────────────────────────────────────
          Positioned(
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).size.height * 0.42 + AppSpacing.md,
            child: Column(
              children: [
                _MapFab(icon: Icons.add, onPressed: _zoomIn),
                const SizedBox(height: 6),
                _MapFab(icon: Icons.remove, onPressed: _zoomOut),
                const SizedBox(height: 6),
                _MapFab(
                  icon: Icons.my_location,
                  onPressed: () => _mapboxMap?.flyTo(
                    CameraOptions(center: Point(coordinates: Position(_userLocation.longitude, _userLocation.latitude)), zoom: 15.0),
                    MapAnimationOptions(duration: 500),
                  ),
                ),
              ],
            ),
          ),

          // ── Draggable sheet ──────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.18,
            maxChildSize: 0.85,
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, -4))],
                ),
                child: Column(
                  children: [
                    const SheetHandle(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Text('Nearby stops', style: AppTypography.headline(20)),
                          const Spacer(),
                          Text('${filtered.length} found', style: GoogleFonts.plusJakartaSans(color: AppColors.outline, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final entry = filtered[i];
                          return _StopTile(
                            stop: entry.stop,
                            meters: entry.meters,
                            selected: _selected?.id == entry.stop.id,
                            onTap: () => _select(entry.stop),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, MediaQuery.of(context).padding.bottom + AppSpacing.lg),
                      child: PrimaryButton(
                        label: _selected == null ? 'Select Stop' : 'Select ${_selected!.name}',
                        icon: Icons.arrow_forward,
                        onPressed: _selected == null
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StopDetailsScreen(stop: _selected!))),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({required this.stop, required this.meters, required this.selected, required this.onTap});
  final BusStop stop;
  final double meters;
  final bool selected;
  final VoidCallback onTap;

  String _badgeCode(String routeId) {
    // Route IDs from DemoRepo are like "r1"; from API they may be "120 - Colombo..."
    if (routeId.startsWith('r') && routeId.length <= 4) return routeId.substring(1);
    final firstWord = routeId.split(RegExp(r'[\s\-–]')).first;
    return firstWord.length > 5 ? firstWord.substring(0, 4) : firstWord;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: selected ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.surfaceContainerLow,
      borderColor: selected ? AppColors.primary.withValues(alpha: 0.4) : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? AppColors.secondary.withValues(alpha: 0.2) : AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Icon(Icons.place, color: selected ? AppColors.secondary : AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stop.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${meters.toStringAsFixed(0)} m · ${stop.routeIds.length} routes',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.outline)),
              ],
            ),
          ),
          Wrap(
            spacing: 4,
            children: stop.routeIds.take(2).map((id) => RouteBadge(code: _badgeCode(id), size: 32)).toList(),
          ),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({required this.icon, required this.onPressed});
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
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12)],
        ),
        child: Icon(icon, color: AppColors.onSurface, size: 20),
      ),
    );
  }
}
