import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/demo_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/route_badge.dart';
import '../widgets/status_chip.dart';
import 'live_tracking_screen.dart';

/// Screen 6 — Filtered bus selection (dark theme).
class FilteredBusSelectionScreen extends StatefulWidget {
  const FilteredBusSelectionScreen({
    super.key,
    required this.stop,
    required this.destination,
  });

  final BusStop stop;
  final String destination;

  @override
  State<FilteredBusSelectionScreen> createState() =>
      _FilteredBusSelectionScreenState();
}

class _FilteredBusSelectionScreenState extends State<FilteredBusSelectionScreen> {
  final _repo = DemoRepository.instance;
  String? _selectedBusId;

  List<({Bus bus, BusPosition pos})> get _sorted {
    final dest = widget.destination.toLowerCase();
    var list = _repo.busesForStop(widget.stop.id).map((b) {
      return (bus: b, pos: _repo.snapshotFor(b.id));
    }).toList();

    if (dest.isNotEmpty) {
      list = list.where((e) {
        final r = _repo.routeById(e.bus.routeId);
        return r.destination.toLowerCase().contains(dest) ||
            r.name.toLowerCase().contains(dest);
      }).toList();
    }

    list.sort((a, b) => a.pos.etaMinutes.compareTo(b.pos.etaMinutes));
    return list;
  }

  @override
  void initState() {
    super.initState();
    final list = _sorted;
    if (list.isNotEmpty) _selectedBusId = list.first.bus.id;
  }

  @override
  Widget build(BuildContext context) {
    final list = _sorted;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Best buses',
                style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface)),
            Text(
              widget.destination.isEmpty ? 'From ${widget.stop.name}' : 'To ${widget.destination}',
              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No buses match.',
                          style: GoogleFonts.manrope(color: AppColors.outline)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) {
                        final item = list[i];
                        final isBest = i == 0;
                        final selected = _selectedBusId == item.bus.id;
                        return _SelectableBusCard(
                          bus: item.bus,
                          pos: item.pos,
                          isBest: isBest,
                          selected: selected,
                          onTap: () => setState(() => _selectedBusId = item.bus.id),
                        );
                      },
                    ),
            ),
            if (_selectedBusId != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  MediaQuery.of(context).padding.bottom + AppSpacing.xl,
                ),
                child: PrimaryButton(
                  label: 'Select Bus',
                  icon: Icons.my_location,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LiveTrackingScreen(busId: _selectedBusId!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectableBusCard extends StatelessWidget {
  const _SelectableBusCard({
    required this.bus,
    required this.pos,
    required this.isBest,
    required this.selected,
    required this.onTap,
  });

  final Bus bus;
  final BusPosition pos;
  final bool isBest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final repo = DemoRepository.instance;
    final route = repo.routeById(bus.routeId);
    final status = _mapStatus(pos.status);

    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.primary.withOpacity(0.5) : null,
      color: selected ? AppColors.primaryContainer.withOpacity(0.2) : AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 12, color: Color(0xFF001F25)),
                  const SizedBox(width: 4),
                  Text('BEST OPTION',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF001F25),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      )),
                ],
              ),
            ),
          Row(
            children: [
              RouteBadge(code: route.code, size: 56),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.name,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    const SizedBox(height: 2),
                    Text('${route.origin}  →  ${route.destination}',
                        style: GoogleFonts.manrope(fontSize: 12, color: AppColors.outline)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${pos.etaMinutes}',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                          height: 1)),
                  Text('min',
                      style: GoogleFonts.manrope(fontSize: 11, color: AppColors.outline)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              StatusChip(status: status, dense: true),
              const SizedBox(width: AppSpacing.sm),
              _MetaPill(icon: Icons.speed, label: '${pos.speedKmh.toStringAsFixed(0)} km/h'),
              const SizedBox(width: AppSpacing.sm),
              _MetaPill(icon: Icons.groups_outlined, label: '${pos.occupancyPct}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}

BusStatus _mapStatus(BusLiveStatus s) {
  switch (s) {
    case BusLiveStatus.onTime:
      return BusStatus.onTime;
    case BusLiveStatus.delayed:
      return BusStatus.delayed;
    case BusLiveStatus.arriving:
      return BusStatus.arriving;
    case BusLiveStatus.cancelled:
      return BusStatus.cancelled;
  }
}
