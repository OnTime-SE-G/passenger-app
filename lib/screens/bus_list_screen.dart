import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/api_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/route_badge.dart';
import '../widgets/search_field.dart';
import '../widgets/status_chip.dart';
import 'live_tracking_screen.dart';

/// Buses serving a selected stop — pick line then track live.
class BusListScreen extends StatefulWidget {
  const BusListScreen({super.key, required this.stop});
  final BusStop stop;

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  final _repo = ApiRepository.instance;
  String _query = '';
  String _activeFilter = 'All';
  List<Bus> _allBuses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    // Fetch routes for this stop, then buses for each route
    final routes = await _repo.fetchRoutesForStop(widget.stop.id);
    final buses = <Bus>[];
    for (final r in routes) {
      final rb = await _repo.fetchBusesForRoute(r.id);
      buses.addAll(rb);
    }
    if (mounted) setState(() { _allBuses = buses; _loading = false; });
  }

  List<Bus> get _buses {
    var list = List<Bus>.from(_allBuses);
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((b) {
        final r = _repo.routeById(b.routeId);
        return b.number.toLowerCase().contains(q) ||
            r.code.toLowerCase().contains(q) ||
            r.destination.toLowerCase().contains(q);
      }).toList();
    }
    if (_activeFilter != 'All') {
      list = list.where((b) {
        switch (_activeFilter) {
          case 'On time':
            return b.status == 'ON_TIME' || b.status == 'RUNNING';
          case 'Delayed':
            return b.status == 'DELAYED';
          case 'Arriving':
            return b.status == 'ARRIVING';
        }
        return true;
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.onSurface,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buses at',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              widget.stop.name,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: SearchField(
                hint: 'Search bus or route',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            _FilterChips(
              active: _activeFilter,
              onChanged: (v) => setState(() => _activeFilter = v),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_bus_outlined,
                            size: 64,
                            color: AppColors.outline.withOpacity(0.4),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No buses match',
                            style: GoogleFonts.inter(color: AppColors.outline),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        AppSpacing.xl,
                      ),
                      itemCount: _buses.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => BusTile(bus: _buses[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BusTile extends StatelessWidget {
  const BusTile({super.key, required this.bus, this.highlight = false});
  final Bus bus;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final repo = ApiRepository.instance;
    final route = repo.routeById(bus.routeId);
    final statusLabel = _statusLabel(bus.status);

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LiveTrackingScreen(busId: bus.id),
        ),
      ),
      borderColor: highlight ? AppColors.primary.withOpacity(0.5) : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          RouteBadge(code: route.code, size: 52),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        route.name.isNotEmpty ? route.name : bus.routeId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    StatusChip(status: statusLabel, dense: true),
                  ],
                ),
                const SizedBox(height: 4),
                if (route.origin.isNotEmpty)
                  Text(
                    '${route.origin}  →  ${route.destination}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.outline,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.tag, size: 14, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text(
                      bus.number,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

BusStatus _statusLabel(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case 'DELAYED':
      return BusStatus.delayed;
    case 'ARRIVING':
      return BusStatus.arriving;
    case 'CANCELLED':
      return BusStatus.cancelled;
    default:
      return BusStatus.onTime;
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onChanged});
  final String active;
  final ValueChanged<String> onChanged;

  static const _filters = ['All', 'On time', 'Arriving', 'Delayed'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = f == active;
          return GestureDetector(
            onTap: () => onChanged(f),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.secondaryContainer.withOpacity(0.55)
                    : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
              child: Center(
                child: Text(
                  f,
                  style: GoogleFonts.inter(
                    color: selected
                        ? AppColors.onSecondaryContainer
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
