import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/demo_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/global_app_bar.dart';

/// Profile screen — mirrors the web "Profile" page.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = DemoRepository.instance;

  // Preferences state
  bool _accessibility = true;
  bool _notifications = true;
  bool _showDelays = true;

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          GlobalHeaderActions(
            onRefresh: _refresh,
            onNotifications: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          100,
        ),
        children: [
          // ── User card ──────────────────────────────────────────────
          _Section(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passenger',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Colombo, Sri Lanka',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit profile coming soon')),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Saved routes ───────────────────────────────────────────
          _SectionHeader(label: 'SAVED ROUTES'),
          const SizedBox(height: AppSpacing.sm),
          ..._repo.savedRoutes.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SavedRouteRow(route: r),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Recent trips ───────────────────────────────────────────
          _SectionHeader(label: 'RECENT TRIPS'),
          const SizedBox(height: AppSpacing.sm),
          ..._repo.recentTrips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RecentTripRow(trip: t),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Preferences ────────────────────────────────────────────
          _SectionHeader(label: 'PREFERENCES'),
          const SizedBox(height: AppSpacing.sm),
          _Section(
            child: Column(
              children: [
                _PrefToggle(
                  label: 'Accessibility (low-floor buses)',
                  value: _accessibility,
                  onChanged: (v) => setState(() => _accessibility = v),
                ),
                const Divider(height: 1, color: Color(0x14000000)),
                _PrefToggle(
                  label: 'Notifications for saved routes',
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                const Divider(height: 1, color: Color(0x14000000)),
                _PrefToggle(
                  label: 'Show delays on map',
                  value: _showDelays,
                  onChanged: (v) => setState(() => _showDelays = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── My Account ─────────────────────────────────────────────
          _SectionHeader(label: 'MY ACCOUNT'),
          const SizedBox(height: AppSpacing.sm),
          _Section(
            child: Column(
              children: [
                _AccountRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0x14000000)),
                _AccountRow(
                  icon: Icons.notifications_outlined,
                  label: 'Push Notification Settings',
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0x14000000)),
                _AccountRow(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  onTap: () {},
                  destructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _SavedRouteRow extends StatefulWidget {
  const _SavedRouteRow({required this.route});
  final SavedRoute route;

  @override
  State<_SavedRouteRow> createState() => _SavedRouteRowState();
}

class _SavedRouteRowState extends State<_SavedRouteRow> {
  bool _starred = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.route.routeCode,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              widget.route.name,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _starred = !_starred),
            child: Icon(
              _starred ? Icons.star_rounded : Icons.star_border_rounded,
              color: _starred ? const Color(0xFFD97706) : AppColors.outlineVariant,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTripRow extends StatelessWidget {
  const _RecentTripRow({required this.trip});
  final RecentTrip trip;

  @override
  Widget build(BuildContext context) {
    final label = _formatTime(trip.at);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.directions_bus_outlined,
                size: 20, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.from} → ${trip.to}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Route ${trip.routeCode} · $label',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return 'Today, ${_hm(t)}';
    if (diff.inHours < 24) return 'Today, ${_hm(t)}';
    if (diff.inDays == 1) return 'Yesterday, ${_hm(t)}';
    return '${_weekday(t)}, ${_hm(t)}';
  }

  String _hm(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  String _weekday(DateTime t) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[t.weekday - 1];
  }
}

class _PrefToggle extends StatelessWidget {
  const _PrefToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.errorBright : AppColors.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color.withOpacity(0.8)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
            if (!destructive)
              Icon(Icons.chevron_right,
                  size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
