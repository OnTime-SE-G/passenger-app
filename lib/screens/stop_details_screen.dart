import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/api_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/route_badge.dart';
import 'bus_list_screen.dart';

/// Bus stop details — routes + departure actions.
class StopDetailsScreen extends StatefulWidget {
  const StopDetailsScreen({super.key, required this.stop});
  final BusStop stop;

  @override
  State<StopDetailsScreen> createState() => _StopDetailsScreenState();
}

class _StopDetailsScreenState extends State<StopDetailsScreen> {
  final _repo = ApiRepository.instance;
  List<BusRoute> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    // Try live API first
    final live = await _repo.fetchRoutesForStop(widget.stop.id);
    if (live.isNotEmpty) {
      setState(() { _routes = live; _loading = false; });
      return;
    }
    // Fall back to matching by name from loaded routes
    final byName = widget.stop.routeIds.map(_repo.routeById).toList();
    setState(() { _routes = byName; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Stop Details',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.onSurface,
            )),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          child: const Icon(Icons.place, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.stop.name, style: AppTypography.headline(20)),
                              const SizedBox(height: 2),
                              Text(widget.stop.address,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(height: 1, color: AppColors.outlineVariant.withOpacity(0.2)),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'ROUTES SERVING THIS STOP',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_routes.isEmpty)
                      Text('No routes found', style: GoogleFonts.inter(color: AppColors.outline))
                    else
                      ..._routes.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Row(
                          children: [
                            RouteBadge(code: r.code),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: AppTypography.headline(16)),
                                  const SizedBox(height: 2),
                                  Text('${r.origin}  →  ${r.destination}',
                                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'View Buses',
                icon: Icons.directions_bus_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BusListScreen(stop: widget.stop)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
