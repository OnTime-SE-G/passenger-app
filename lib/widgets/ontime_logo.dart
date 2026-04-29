import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// OnTime brand logo widget — bus icon + wordmark. Used in app bars & splash.
class OnTimeLogo extends StatelessWidget {
  const OnTimeLogo({
    super.key,
    this.size = OnTimeLogoSize.normal,
    this.showText = true,
  });

  final OnTimeLogoSize size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final double iconSize;
    final double fontSize;
    final double gap;

    switch (size) {
      case OnTimeLogoSize.small:
        iconSize = 28;
        fontSize = 16;
        gap = 8;
      case OnTimeLogoSize.normal:
        iconSize = 32;
        fontSize = 18;
        gap = 10;
      case OnTimeLogoSize.large:
        iconSize = 56;
        fontSize = 32;
        gap = 14;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bus icon with clock accent
        _BusIcon(size: iconSize),
        if (showText) ...[
          SizedBox(width: gap),
          Text(
            'On Time',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

enum OnTimeLogoSize { small, normal, large }

/// Custom bus icon with an integrated clock marker.
class _BusIcon extends StatelessWidget {
  const _BusIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Glow background
          Center(
            child: Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.25),
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bus body
          Center(
            child: Container(
              width: size * 0.85,
              height: size * 0.65,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(size * 0.18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: size * 0.25,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Windows row
                  Positioned(
                    top: size * 0.08,
                    left: size * 0.1,
                    right: size * 0.18,
                    child: Row(
                      children: List.generate(3, (i) {
                        return Expanded(
                          child: Container(
                            height: size * 0.18,
                            margin: EdgeInsets.only(right: i < 2 ? size * 0.04 : 0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(size * 0.04),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Headlight
                  Positioned(
                    right: size * 0.06,
                    top: size * 0.12,
                    child: Container(
                      width: size * 0.1,
                      height: size * 0.1,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: size * 0.12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Clock badge (top-left)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.schedule,
                size: size * 0.18,
                color: AppColors.primary,
              ),
            ),
          ),
          // Wheels
          Positioned(
            bottom: size * 0.05,
            left: size * 0.18,
            child: _MiniWheel(size: size * 0.14),
          ),
          Positioned(
            bottom: size * 0.05,
            right: size * 0.18,
            child: _MiniWheel(size: size * 0.14),
          ),
        ],
      ),
    );
  }
}

class _MiniWheel extends StatelessWidget {
  const _MiniWheel({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
      ),
    );
  }
}

/// Image-based logo for use in splash/about screens.
class OnTimeLogoImage extends StatelessWidget {
  const OnTimeLogoImage({super.key, this.width = 180});
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/images/ontime_logo.png',
        width: width,
        fit: BoxFit.contain,
      ),
    );
  }
}
