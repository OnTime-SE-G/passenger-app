import 'package:flutter/material.dart';

import '../app_bootstrap.dart';
import '../theme/app_colors.dart';
import 'app_shell.dart';

/// Full-screen splash: shows for 2s. [AppBootstrap] runs in parallel during that time.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    AppBootstrap.ensureReady();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fill = AppColors.splashIconBackdrop;
    return Scaffold(
      backgroundColor: fill,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: fill),
          Positioned.fill(
            child: Image.asset(
              'splash_image.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );
  }
}
