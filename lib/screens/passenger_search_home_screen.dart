import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/api_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/map_widgets.dart';
import '../widgets/primary_button.dart';
import '../widgets/ontime_logo.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/sheet_handle.dart';
import '../services/app_tab_controller.dart';
import 'nearby_stops_screen.dart';

/// Search home: origin / destination card, map preview, recent searches.
class PassengerSearchHomeScreen extends StatefulWidget {
  const PassengerSearchHomeScreen({super.key});

  @override
  State<PassengerSearchHomeScreen> createState() =>
      _PassengerSearchHomeScreenState();
}

class _PassengerSearchHomeScreenState extends State<PassengerSearchHomeScreen> {
  final _repo = ApiRepository.instance;
  final _mapCtl = MapController();
  final _originCtl = TextEditingController();
  final _destinationCtl = TextEditingController();

  /// `null` means depart as soon as possible ("Leave now").
  DateTime? _departureAt;

  bool _preferFewerTransfers = false;
  bool _preferLessWalking = false;
  bool _wheelchairAccessible = false;

  @override
  void dispose() {
    _originCtl.dispose();
    _destinationCtl.dispose();
    super.dispose();
  }

  String get _networkStatus {
    final buses = _repo.buses;
    if (buses.any((b) => b.status == 'breakdown' || b.status == 'incident')) {
      return 'Service Disruptions';
    }
    if (buses.any((b) => b.status == 'delayed')) {
      return 'Minor Delays';
    }
    return 'Good Service';
  }

  Color get _networkStatusColor {
    switch (_networkStatus) {
      case 'Service Disruptions':
        return const Color(0xFFDC2626);
      case 'Minor Delays':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _repo.userLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          OnTimeLogo(size: OnTimeLogoSize.normal),
                        ],
                      ),
                    ),
                    GlobalHeaderActions(
                      onRefresh: () {
                        ApiRepository.instance.refresh().then((_) {
                          if (context.mounted) setState(() {});
                        });
                      },
                      onNotifications: () {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const NotificationsSheet(),
                        );
                      },
                      onSettings: () {
                        AppTabController.instance.jumpTo(5);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where to?',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.9,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Find the best route across the transit network.',
                      style: AppTypography.body(15, weight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Search card (origin / destination)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: kAmbientShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InputRow(
                            icon: Icons.my_location,
                            iconFilled: true,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Origin',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                              ),
                              controller: _originCtl,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(left: 22),
                                  width: 2,
                                  height: 22,
                                  color: AppColors.surfaceContainerHigh,
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    final origin = _originCtl.text;
                                    final dest = _destinationCtl.text;
                                    setState(() {
                                      _originCtl.text = dest;
                                      _destinationCtl.text = origin;
                                    });
                                  },
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withOpacity(0.10),
                                    child: const Icon(
                                      Icons.swap_vert,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _InputRow(
                            icon: Icons.place_outlined,
                            iconFilled: false,
                            child: TextField(
                              controller: _destinationCtl,
                              decoration: const InputDecoration(
                                hintText: 'Destination',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: GoogleFonts.inter(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showDepartureSheet,
                                  icon: const Icon(Icons.schedule, size: 18),
                                  label: Text(_departureButtonLabel),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              TextButton(
                                onPressed: _showRouteOptionsSheet,
                                child: Text(
                                  'Options',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          PrimaryButton(
                            label: 'Search Route',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              final dest = _destinationCtl.text.trim();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => NearbyStopsScreen(
                                    destinationQuery:
                                        dest.isEmpty ? null : dest,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_repo.recentSearches.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'RECENT SEARCHES',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ..._repo.recentSearches.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.cardRadius),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const NearbyStopsScreen(),
                                  ),
                                );
                              },
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius,
                                  ),
                                  boxShadow: kAmbientShadow,
                                ),
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          AppColors.surfaceContainer,
                                      child: Icon(
                                        Icons.history,
                                        color: AppColors.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${r.from} → ${r.to}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Saved route · tap to open stops',
                                            style: AppTypography.body(13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ] else
                      const SizedBox(height: AppSpacing.xxl),

                    // Map preview — asymmetric column second half on web; stacked on mobile.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      child: SizedBox(
                        height: 280,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            buildMap(
                              controller: _mapCtl,
                              center: center,
                              zoom: 13,
                              interactive: false,
                              layers: [
                                const AppMapTiles(),
                                PolylineLayer(
                                  polylines: _repo.routes.map((route) {
                                    return Polyline(
                                      points: route.path,
                                      strokeWidth: 3,
                                      color: AppColors.primary.withOpacity(
                                        0.75,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: center,
                                      width: 48,
                                      height: 48,
                                      child: const UserLocationMarker(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              left: AppSpacing.md,
                              right: AppSpacing.md,
                              bottom: AppSpacing.md,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 16,
                                    sigmaY: 16,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: glassPanelDecoration(radius: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _networkStatusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                              children: [
                                                const TextSpan(text: 'Live Network: '),
                                                TextSpan(
                                                  text: _networkStatus,
                                                  style: TextStyle(color: _networkStatusColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            ApiRepository.instance.refresh().then((_) {
                                              if (context.mounted) setState(() {});
                                            });
                                          },
                                          icon: const Icon(Icons.my_location),
                                          color: AppColors.primary,
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _departureButtonLabel {
    if (_departureAt == null) return 'Leave Now';
    final d = _departureAt!;
    final today = DateTime.now();
    if (d.year == today.year &&
        d.month == today.month &&
        d.day == today.day) {
      return 'Depart ${DateFormat.jm().format(d)}';
    }
    return 'Depart ${DateFormat('EEE MMM d, h:mm a').format(d)}';
  }

  Future<void> _pickScheduledDeparture() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: (_departureAt ?? now).isBefore(today) ? today : (_departureAt ?? now),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureAt ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _departureAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _showDepartureSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              Text(
                'When are you leaving?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flash_on_outlined),
                title: Text(
                  'Leave now',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Best routes for immediate departure',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  setState(() => _departureAt = null);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  'Choose date & time',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickScheduledDeparture();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRouteOptionsSheet() async {
    var fewer = _preferFewerTransfers;
    var walking = _preferLessWalking;
    var access = _wheelchairAccessible;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHandle(),
                  Text(
                    'Route options',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Preferences for upcoming trip planning.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Fewer transfers', style: GoogleFonts.inter()),
                    value: fewer,
                    onChanged: (v) => setModal(() => fewer = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Less walking', style: GoogleFonts.inter()),
                    value: walking,
                    onChanged: (v) => setModal(() => walking = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Wheelchair-accessible', style: GoogleFonts.inter()),
                    value: access,
                    onChanged: (v) => setModal(() => access = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _preferFewerTransfers = fewer;
                        _preferLessWalking = walking;
                        _wheelchairAccessible = access;
                      });
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.icon,
    required this.child,
    this.iconFilled = false,
  });

  final IconData icon;
  final Widget child;
  final bool iconFilled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Icon(
              icon,
              size: 20,
              color: iconFilled ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
