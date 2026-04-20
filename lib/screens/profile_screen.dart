import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ontime_logo.dart';

/// Profile placeholder screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () {},
        ),
        title: const OnTimeLogo(size: OnTimeLogoSize.small),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.person, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Alex', style: AppTypography.headline(24)),
            const SizedBox(height: AppSpacing.sm),
            Text('alex@signalflux.com', style: AppTypography.body(14)),
            const SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
              child: Text(
                'Profile settings will be available once the central database is connected.',
                textAlign: TextAlign.center,
                style: AppTypography.body(13, color: AppColors.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
