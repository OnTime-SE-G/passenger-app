import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/demo_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/global_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = DemoRepository.instance;
  bool _accessibility = true;
  bool _notifications = true;
  bool _showDelays = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Profile',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.onSurface)),
        actions: [
          GlobalHeaderActions(onRefresh: () => setState(() {})),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            MediaQuery.of(context).padding.bottom + 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User card
                _card(
                  Row(children: [
                    CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 36)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Passenger',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  color: AppColors.onSurface)),
                          Text('Colombo, Sri Lanka',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant)),
                        ])),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color: AppColors.primary.withOpacity(0.4)),
                          textStyle: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Saved Routes
                _header('SAVED ROUTES'),
                const SizedBox(height: AppSpacing.sm),
                for (final r in _repo.savedRoutes) ...[
                  _SavedRouteRow(route: r),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.xl),

                // Recent Trips
                _header('RECENT TRIPS'),
                const SizedBox(height: AppSpacing.sm),
                for (final t in _repo.recentTrips) ...[
                  _TripRow(trip: t),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.xl),

                // Preferences
                _header('PREFERENCES'),
                const SizedBox(height: AppSpacing.sm),
                _card(Column(children: [
                  _toggle('Accessibility (low-floor buses)', _accessibility,
                      (v) => setState(() => _accessibility = v)),
                  const Divider(height: 1, color: Color(0x14000000)),
                  _toggle('Notifications for saved routes', _notifications,
                      (v) => setState(() => _notifications = v)),
                  const Divider(height: 1, color: Color(0x14000000)),
                  _toggle('Show delays on map', _showDelays,
                      (v) => setState(() => _showDelays = v)),
                ])),
                const SizedBox(height: AppSpacing.xl),

                // My Account
                _header('MY ACCOUNT'),
                const SizedBox(height: AppSpacing.sm),
                _card(Column(children: [
                  _accountRow(Icons.lock_outline_rounded, 'Change Password',
                      () {}, false),
                  const Divider(height: 1, color: Color(0x14000000)),
                  _accountRow(Icons.notifications_outlined,
                      'Push Notification Settings', () {}, false),
                  const Divider(height: 1, color: Color(0x14000000)),
                  _accountRow(
                      Icons.logout_rounded, 'Sign Out', () {}, true),
                ])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: child,
      );

  Widget _header(String label) => Text(label,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.onSurfaceVariant));

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: AppColors.onSurface))),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary),
        ]),
      );

  Widget _accountRow(
      IconData icon, String label, VoidCallback onTap, bool destructive) {
    final color =
        destructive ? AppColors.errorBright : AppColors.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, size: 20, color: color.withOpacity(0.8)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: color))),
          if (!destructive)
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.onSurfaceVariant),
        ]),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(widget.route.routeCode,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primary)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: Text(widget.route.name,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.onSurface))),
        GestureDetector(
          onTap: () => setState(() => _starred = !_starred),
          child: Icon(
              _starred ? Icons.star_rounded : Icons.star_border_rounded,
              color: _starred
                  ? const Color(0xFFD97706)
                  : AppColors.outlineVariant,
              size: 24),
        ),
      ]),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});
  final RecentTrip trip;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(Icons.directions_bus_outlined,
              size: 20, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('${trip.from} → ${trip.to}',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.onSurface)),
              Text('Route ${trip.routeCode} · ${_lbl(trip.at)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppColors.onSurfaceVariant)),
            ])),
      ]),
    );
  }

  String _lbl(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inHours < 24) return 'Today, ${_hm(t)}';
    if (d.inDays == 1) return 'Yesterday, ${_hm(t)}';
    return '${['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][t.weekday-1]}, ${_hm(t)}';
  }

  String _hm(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2,'0')} ${t.hour<12?'AM':'PM'}';
  }
}
