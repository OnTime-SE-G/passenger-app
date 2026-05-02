import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Mirrors the web notification panel popup.
/// Call [NotificationsSheet.show] to open it as a modal bottom sheet.
class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtl =
      TabController(length: 4, vsync: this);

  bool _toggleNotifications = true;
  final _unreadIds = {0, 1}; // indices of unread items

  final _notifications = [
    _NotifItem(
      icon: Icons.directions_bus_rounded,
      iconBg: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF2563EB),
      title: 'Bus 120 arriving in 5 minutes',
      subtitle: 'Central Station',
      time: '2 mins ago',
      accent: const Color(0xFF2563EB),
      tag: 'arrival',
    ),
    _NotifItem(
      icon: Icons.warning_amber_rounded,
      iconBg: const Color(0xFFFEF2F2),
      iconColor: const Color(0xFFDC2626),
      title: 'Bus 138 delayed by 10 minutes',
      subtitle: 'North Route',
      time: '15 mins ago',
      accent: const Color(0xFFDC2626),
      tag: 'delay',
    ),
    _NotifItem(
      icon: Icons.route_rounded,
      iconBg: const Color(0xFFF5F3FF),
      iconColor: const Color(0xFF7C3AED),
      title: 'Route 101 has been updated',
      subtitle: 'System Update',
      time: '1 hr ago',
      accent: null,
      tag: 'update',
    ),
    _NotifItem(
      icon: Icons.directions_bus_outlined,
      iconBg: const Color(0xFFF0FDF4),
      iconColor: const Color(0xFF059669),
      title: 'Your bus is now active on road',
      subtitle: 'Dispatch',
      time: '2 hrs ago',
      accent: null,
      tag: 'update',
    ),
    _NotifItem(
      icon: Icons.check_circle_rounded,
      iconBg: const Color(0xFFF0FDF4),
      iconColor: const Color(0xFF059669),
      title: 'Trip completed successfully',
      subtitle: 'System Log',
      time: '3 hrs ago',
      accent: null,
      tag: 'update',
    ),
  ];

  List<_NotifItem> _filtered(String tab) {
    switch (tab) {
      case 'Unread':
        return [
          for (var i = 0; i < _notifications.length; i++)
            if (_unreadIds.contains(i)) _notifications[i]
        ];
      case 'Delays':
        return _notifications.where((n) => n.tag == 'delay').toList();
      case 'Updates':
        return _notifications.where((n) => n.tag == 'update').toList();
      default:
        return _notifications;
    }
  }

  @override
  void dispose() {
    _tabCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unreadIds.length;
    final tabs = ['All', 'Unread', 'Delays', 'Updates'];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle ────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$unreadCount Unread',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),

            // ── Tabs ──────────────────────────────────────────────────
            TabBar(
              controller: _tabCtl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceVariant,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
              onTap: (_) => setState(() {}),
            ),

            // ── Mark all as read ──────────────────────────────────────
            if (_unreadIds.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding:
                      const EdgeInsets.only(right: 16, top: 8, bottom: 2),
                  child: GestureDetector(
                    onTap: () => setState(() => _unreadIds.clear()),
                    child: Text(
                      'Mark all as read',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),

            // ── List ──────────────────────────────────────────────────
            Expanded(
              child: AnimatedBuilder(
                animation: _tabCtl,
                builder: (_, __) {
                  final items =
                      _filtered(tabs[_tabCtl.index]);
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No notifications',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final globalIdx = _notifications.indexOf(item);
                      final isUnread = _unreadIds.contains(globalIdx);
                      return _NotifTile(
                        item: item,
                        isUnread: isUnread,
                        onTap: () => setState(
                            () => _unreadIds.remove(globalIdx)),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Footer ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.outlineVariant)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Toggle Notifications',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _toggleNotifications,
                        onChanged: (v) =>
                            setState(() => _toggleNotifications = v),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _unreadIds.clear()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: BorderSide(color: AppColors.outlineVariant),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data & sub-widgets ────────────────────────────────────────────────────

class _NotifItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final Color? accent; // left border for unread, null = read style
  final String tag;

  const _NotifItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.accent,
    required this.tag,
  });
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.item,
    required this.isUnread,
    required this.onTap,
  });
  final _NotifItem item;
  final bool isUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: isUnread && item.accent != null
                  ? item.accent!
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, size: 20, color: item.iconColor),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: isUnread
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                      color: isUnread
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.subtitle} • ${item.time}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Unread dot
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
