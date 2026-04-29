import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum BusStatus { onTime, delayed, arriving, cancelled }

extension BusStatusX on BusStatus {
  String get label {
    switch (this) {
      case BusStatus.onTime:
        return 'LIVE';
      case BusStatus.delayed:
        return 'DELAYED';
      case BusStatus.arriving:
        return 'ARRIVING';
      case BusStatus.cancelled:
        return 'OFFLINE';
    }
  }

  Color get color {
    switch (this) {
      case BusStatus.onTime:
        return AppColors.success;
      case BusStatus.delayed:
        return AppColors.errorBright;
      case BusStatus.arriving:
        return AppColors.primary;
      case BusStatus.cancelled:
        return AppColors.outline;
    }
  }
}

/// Pill-shaped status chip with pulsing dot.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.dense = false});

  final BusStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: status.color.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: status.color, size: dense ? 5 : 6),
          SizedBox(width: dense ? 4 : 6),
          Text(
            status.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: dense ? 9 : 10,
              fontWeight: FontWeight.w800,
              color: status.color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, this.size = 6});
  final Color color;
  final double size;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.6 + 0.4 * (1 - _c.value),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
