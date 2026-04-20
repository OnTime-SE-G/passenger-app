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
import 'bus_list_screen.dart';

/// Screen 3 — Bus stop details (dark theme).
class StopDetailsScreen extends StatelessWidget {
  const StopDetailsScreen({super.key, required this.stop});
  final BusStop stop;

  @override
  Widget build(BuildContext context) {
    final repo = DemoRepository.instance;
    final routes = stop.routeIds.map(repo.routeById).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Stop Details',
            style: GoogleFonts.spaceGrotesk(
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
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          child: const Icon(Icons.place, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stop.name, style: AppTypography.headline(20)),
                              const SizedBox(height: 2),
                              Text(stop.address,
                                  style: GoogleFonts.manrope(fontSize: 13, color: AppColors.onSurfaceVariant)),
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
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...routes.map((r) => Padding(
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
                                        style: GoogleFonts.manrope(
                                            fontSize: 13, color: AppColors.onSurfaceVariant)),
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
                  MaterialPageRoute(builder: (_) => BusListScreen(stop: stop)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
