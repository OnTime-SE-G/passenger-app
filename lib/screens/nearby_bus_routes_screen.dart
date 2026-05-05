import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/api_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/ontime_logo.dart';
import 'live_tracking_screen.dart';

/// Active routes nearby — filters + ETA rows + jump to live tracking.
class NearbyBusRoutesScreen extends StatefulWidget {
  const NearbyBusRoutesScreen({super.key});

  @override
  State<NearbyBusRoutesScreen> createState() => _NearbyBusRoutesScreenState();
}

class _NearbyBusRoutesScreenState extends State<NearbyBusRoutesScreen> {
  final _repo = ApiRepository.instance;
  final _destinationFilter = TextEditingController();
  int _sortOption = 0;
  static const _sortLabels = ['Route Name', 'Status', 'Route Number'];
  List<_BusRowVm> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    final buses = await _repo.getLiveBuses();
    final rows = <_BusRowVm>[];
    for (final bus in buses) {
      final route = _repo.routeById(bus.routeId);
      final delayed = (bus.status ?? '').toUpperCase() == 'DELAYED';
      rows.add(_BusRowVm(bus: bus, route: route, delayed: delayed));
    }
    if (mounted) setState(() { _rows = rows; _loading = false; });
  }

  @override
  void dispose() {
    _destinationFilter.dispose();
    super.dispose();
  }

  List<_BusRowVm> _buildRows() {
    var rows = List<_BusRowVm>.from(_rows);
    final dest = _destinationFilter.text.trim().toLowerCase();
    if (dest.isNotEmpty) {
      rows.retainWhere(
        (r) => r.route.destination.toLowerCase().contains(dest) ||
               r.route.name.toLowerCase().contains(dest),
      );
    }
    rows.sort((a, b) {
      switch (_sortOption) {
        case 1:
          return a.delayed == b.delayed ? 0 : (a.delayed ? 1 : -1);
        case 2:
          return a.route.code.compareTo(b.route.code);
        default:
          return a.route.name.compareTo(b.route.name);
      }
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const OnTimeLogo(size: OnTimeLogoSize.small),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    color: AppColors.navInactive,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  120,
                ),
                children: [
                  Text(
                    'Active Routes',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${rows.length} ${rows.length == 1 ? 'bus' : 'buses'} available',
                    style: AppTypography.body(15),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: List.generate(_sortLabels.length, (i) {
                      final sel = _sortOption == i;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: i < _sortLabels.length - 1 ? 6.0 : 0,
                          ),
                          child: ChoiceChip(
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(_sortLabels[i]),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                            selected: sel,
                            onSelected: (_) => setState(() => _sortOption = i),
                            selectedColor: AppColors.secondary.withOpacity(0.14),
                            showCheckmark: false,
                            labelStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: sel ? AppColors.secondary : AppColors.onSurface,
                            ),
                            backgroundColor: AppColors.surfaceContainerHigh,
                            side: BorderSide.none,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Destination filter card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: kAmbientShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt_outlined,
                            color: AppColors.outline),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _destinationFilter,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText:
                                  'Filter by destination (e.g. North Station)',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_destinationFilter.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _destinationFilter.clear();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (rows.isEmpty)
                    _EmptyFilterState()
                  else
                    ...rows.map(
                      (row) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _BusRouteCard(
                          row: row,
                          onSelect: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => LiveTrackingScreen(
                                  busId: row.bus.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusRowVm {
  _BusRowVm({
    required this.bus,
    required this.route,
    required this.delayed,
  });

  final Bus bus;
  final BusRoute route;
  final bool delayed;
}

class _BusRouteCard extends StatelessWidget {
  const _BusRouteCard({
    required this.row,
    required this.onSelect,
  });

  final _BusRowVm row;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final bgBadge = row.delayed
        ? AppColors.surfaceContainerHigh
        : AppColors.primary.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: kAmbientShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgBadge,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Text(
              row.route.code,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: row.delayed
                    ? AppColors.onSurfaceVariant
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.route.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: row.delayed
                            ? AppColors.errorBright.withOpacity(0.12)
                            : AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: row.delayed
                                  ? AppColors.errorBright
                                  : AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            row.delayed ? 'Delayed' : 'Active',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: row.delayed
                                  ? AppColors.errorBright
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_bus,
                            size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          row.bus.number,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryFixedDim],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSelect,
                borderRadius:
                    BorderRadius.circular(AppSpacing.buttonRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    'Select Bus',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 14,
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

class _EmptyFilterState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: kAmbientShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 56, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Buses Found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try adjusting your filter to see more results.',
            style: AppTypography.body(14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
