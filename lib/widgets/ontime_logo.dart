import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// OnTime brand logo widget — blue wordmark with 'PUBLIC TRANSPORT' subtitle.
class OnTimeLogo extends StatelessWidget {
  const OnTimeLogo({
    super.key,
    this.size = OnTimeLogoSize.normal,
    this.showText = true,
  });

  final OnTimeLogoSize size;
  final bool showText; // showText isn't strictly necessary since it's only text now, but kept for compatibility.

  @override
  Widget build(BuildContext context) {
    if (!showText) return const SizedBox.shrink();

    final double titleSize;
    final double subtitleSize;

    switch (size) {
      case OnTimeLogoSize.small:
        titleSize = 20;
        subtitleSize = 10;
      case OnTimeLogoSize.normal:
        titleSize = 26;
        subtitleSize = 13;
      case OnTimeLogoSize.large:
        titleSize = 36;
        subtitleSize = 16;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'On Time',
          style: GoogleFonts.inter(
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2563EB), // Blue color from the mockup
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        Text(
          'PUBLIC TRANSPORT',
          style: GoogleFonts.inter(
            fontSize: subtitleSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B), // Slate gray color
            letterSpacing: 1.2,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

enum OnTimeLogoSize { small, normal, large }

class OnTimeLogoImage extends StatelessWidget {
  const OnTimeLogoImage({super.key, this.width = 180});
  final double width;

  @override
  Widget build(BuildContext context) {
    return const OnTimeLogo(size: OnTimeLogoSize.large);
  }
}
