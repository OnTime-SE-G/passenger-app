import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/demo_repository.dart';
import '../services/app_tab_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'alerts_screen.dart';
import 'live_tracking_screen.dart';
import 'nearby_bus_routes_screen.dart';
import 'nearby_stops_screen.dart';
import 'passenger_search_home_screen.dart';
import 'profile_screen.dart';

/// Main shell — floating pill nav with blur (distinct mobile chrome).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _ctrl = AppTabController.instance;

  static const _tabs = [
    _Tab(icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: 'Search'),
    _Tab(icon: Icons.near_me_outlined, activeIcon: Icons.near_me_rounded, label: 'Stops'),
    _Tab(icon: Icons.directions_bus_outlined, activeIcon: Icons.directions_bus_rounded, label: 'Routes'),
    _Tab(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Live'),
    _Tab(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Alerts'),
    _Tab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTabChange);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() => setState(() {});

  Widget _pageForIndex() {
    switch (_ctrl.index) {
      case 0: return const PassengerSearchHomeScreen();
      case 1: return const NearbyStopsScreen();
      case 2: return const NearbyBusRoutesScreen();
      case 3: return const LiveMapPlaceholder();
      case 4: return const AlertsScreen();
      case 5: return const ProfileScreen();
      default: return const PassengerSearchHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _pageForIndex(),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _ctrl.index,
        tabs: _tabs,
        onTap: (i) => _ctrl.jumpTo(i),
        alertCount: DemoRepository.instance.alerts.length,
      ),
    );
  }
}

class LiveMapPlaceholder extends StatelessWidget {
  const LiveMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const LiveTrackingScreen(busId: 'b1');
  }
}

class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
    this.alertCount = 0,
  });

  final int currentIndex;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.sheetRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.sheetRadius),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.9)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.96),
                  Colors.white.withOpacity(0.88),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(tabs.length, (i) {
                    final tab = tabs[i];
                    final active = i == currentIndex;
                    // Show badge on Alerts tab (index 4)
                    final showBadge = i == 4 && alertCount > 0;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onTap(i),
                        borderRadius: BorderRadius.circular(24),
                        splashColor: AppColors.primary.withOpacity(0.08),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: active ? 14 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    active ? tab.activeIcon : tab.icon,
                                    size: 22,
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.navInactive,
                                  ),
                                  if (showBadge)
                                    Positioned(
                                      top: -4,
                                      right: -6,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$alertCount',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                child: active
                                    ? Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Text(
                                          tab.label,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
