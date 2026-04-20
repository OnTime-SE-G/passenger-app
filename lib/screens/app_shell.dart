import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'home_screen.dart';
import 'live_tracking_screen.dart';
import 'routes_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';

/// Root shell with the glassmorphic bottom nav bar matching Signal Flux.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    _Tab(icon: Icons.home_max, activeIcon: Icons.home_max, label: 'HOME'),
    _Tab(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'LIVE MAP'),
    _Tab(icon: Icons.directions_bus_outlined, activeIcon: Icons.directions_bus, label: 'ROUTES'),
    _Tab(icon: Icons.notifications_active_outlined, activeIcon: Icons.notifications_active, label: 'ALERTS'),
    _Tab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'PROFILE'),
  ];

  Widget _buildPage() {
    switch (_index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const LiveMapPlaceholder();
      case 2:
        return const RoutesScreen();
      case 3:
        return const AlertsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildPage(),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        tabs: _tabs,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Placeholder for live map tab entry (user navigates to full tracking from home).
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
  const _Tab({required this.icon, required this.activeIcon, required this.label});
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  final int currentIndex;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, -8)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (i) {
                  final tab = tabs[i];
                  final active = i == currentIndex;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: active ? AppSpacing.md : AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.secondary.withOpacity(0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            active ? tab.activeIcon : tab.icon,
                            color: active
                                ? AppColors.secondary
                                : AppColors.onSurfaceVariant.withOpacity(0.6),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? AppColors.secondary
                                  : AppColors.onSurfaceVariant.withOpacity(0.6),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
