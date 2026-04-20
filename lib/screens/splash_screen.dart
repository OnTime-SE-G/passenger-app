import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../widgets/map_widgets.dart';
import '../widgets/ontime_logo.dart';
import 'app_shell.dart';

/// Animated splash screen — dark map background, bus drives across, then launch.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _busCtl;
  late final AnimationController _fadeCtl;
  late final AnimationController _pulseCtl;
  late final AnimationController _mapZoomCtl;
  late final Animation<double> _busSlide;
  late final Animation<double> _busBounce;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;
  late final Animation<double> _mapZoom;
  late final Animation<double> _mapOpacity;

  final _mapCtl = MapController();

  @override
  void initState() {
    super.initState();

    _busCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _busSlide = CurvedAnimation(parent: _busCtl, curve: Curves.easeOutCubic);
    _busBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _busCtl,
      curve: const Interval(0.5, 1.0),
    ));

    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Map slowly zooms in during the whole sequence
    _mapZoomCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _mapZoom = Tween(begin: 12.0, end: 14.5).animate(
      CurvedAnimation(parent: _mapZoomCtl, curve: Curves.easeOut),
    );
    _mapOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mapZoomCtl, curve: const Interval(0.0, 0.3)),
    );

    _fadeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _busCtl, curve: const Interval(0.0, 0.4)),
    );
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeCtl, curve: Curves.easeInCubic),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Start map zoom immediately
    _mapZoomCtl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _busCtl.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    _pulseCtl.repeat(reverse: true);
    await _busCtl.forward().orCancel;
    await Future.delayed(const Duration(milliseconds: 600));
    _fadeCtl.forward();
    await _fadeCtl.forward().orCancel;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _busCtl.dispose();
    _fadeCtl.dispose();
    _pulseCtl.dispose();
    _mapZoomCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_busCtl, _fadeCtl, _pulseCtl, _mapZoomCtl]),
        builder: (_, __) {
          // Animate the map zoom
          try {
            _mapCtl.move(
              const LatLng(12.9716, 77.5946),
              _mapZoom.value,
            );
          } catch (_) {}

          return Opacity(
            opacity: _fadeOut.value,
            child: Stack(
              children: [
                // Dark map background
                Opacity(
                  opacity: _mapOpacity.value,
                  child: FlutterMap(
                    mapController: _mapCtl,
                    options: const MapOptions(
                      initialCenter: LatLng(12.9716, 77.5946),
                      initialZoom: 12,
                      interactionOptions: InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: const [
                      AppMapTiles(),
                    ],
                  ),
                ),

                // Vignette overlay on the map (dark edges, lighter center)
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: [
                        AppColors.background.withOpacity(0.3),
                        AppColors.background.withOpacity(0.7),
                        AppColors.background.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),

                // Animated cyan route lines overlaying the map
                Positioned.fill(
                  child: Opacity(
                    opacity: (_fadeIn.value * 0.5).clamp(0.0, 0.5),
                    child: CustomPaint(
                      painter: _RouteLinesPainter(
                        progress: _busSlide.value,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),

                // Indigo glow behind the bus area
                Center(
                  child: Transform.translate(
                    offset: Offset(0, -size.height * 0.08),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryContainer.withOpacity(0.2 * _fadeIn.value),
                            AppColors.secondary.withOpacity(0.05 * _fadeIn.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Road
                Positioned(
                  bottom: size.height * 0.38,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _fadeIn.value,
                    child: const _Road(),
                  ),
                ),

                // Bus sliding in
                Positioned(
                  bottom: size.height * 0.38 + 12,
                  left: _busSlide.value * (size.width * 0.5 - 32) - 64,
                  child: Transform.translate(
                    offset: Offset(0, _busBounce.value),
                    child: _AnimatedBus(pulse: _pulseCtl),
                  ),
                ),

                // Logo image + brand text
                Positioned(
                  bottom: size.height * 0.16,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (_busSlide.value * 2).clamp(0.0, 1.0),
                    child: Column(
                      children: [
                        const OnTimeLogoImage(width: 120),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ).createShader(bounds),
                          child: Text(
                            'OnTime',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'LIVE TRANSIT TRACKER',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading dots
                Positioned(
                  bottom: size.height * 0.10,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _fadeIn.value,
                    child: _LoadingDots(progress: _busSlide.value),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Draws animated route lines across the screen like transit paths.
class _RouteLinesPainter extends CustomPainter {
  _RouteLinesPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = ui.Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(
        size.width * 0.25, size.height * 0.15,
        size.width * 0.55, size.height * 0.45,
        size.width * progress, size.height * 0.35,
      );

    final path2 = ui.Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..cubicTo(
        size.width * 0.35, size.height * 0.55,
        size.width * 0.7, size.height * 0.65,
        size.width * 0.9 * progress, size.height * 0.5,
      );

    final path3 = ui.Path()
      ..moveTo(size.width * 0.3, size.height * 0.85)
      ..cubicTo(
        size.width * 0.5, size.height * 0.75,
        size.width * 0.7, size.height * 0.8,
        size.width * progress, size.height * 0.72,
      );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, dashPaint);
    canvas.drawPath(path3, dashPaint);

    if (progress > 0.2) {
      final dotPaint = Paint()..color = color;
      final metrics1 = path1.computeMetrics().firstOrNull;
      if (metrics1 != null) {
        final pos = metrics1.getTangentForOffset(metrics1.length)?.position;
        if (pos != null) {
          canvas.drawCircle(pos, 4, dotPaint);
          canvas.drawCircle(pos, 8, Paint()..color = color.withOpacity(0.2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteLinesPainter old) =>
      old.progress != progress;
}

/// The road with dashed center line.
class _Road extends StatelessWidget {
  const _Road();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(12, (i) {
                    return Container(
                      width: 16,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: AppColors.outlineVariant.withOpacity(0.4),
                    );
                  }),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(height: 2, color: AppColors.secondary.withOpacity(0.08)),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(height: 2, color: AppColors.secondary.withOpacity(0.08)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The bus with headlight glow.
class _AnimatedBus extends StatelessWidget {
  const _AnimatedBus({required this.pulse});
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Headlight beam
          Positioned(
            right: -20,
            top: -2,
            child: Opacity(
              opacity: 0.3 + 0.4 * pulse.value,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.7),
                      AppColors.secondary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Bus body
          Container(
            width: 64,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(4, 4),
                ),
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  left: 8,
                  right: 14,
                  child: Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Container(
                          height: 10,
                          margin: EdgeInsets.only(right: i < 2 ? 3 : 0),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.9),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Icon(Icons.directions_bus, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          // Wheels
          Positioned(bottom: -4, left: 10, child: _Wheel()),
          Positioned(bottom: -4, right: 10, child: _Wheel()),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant, width: 2),
      ),
    );
  }
}

/// Three dots that fill as the bus progresses.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final threshold = (i + 1) / 3;
        final active = progress >= threshold;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: active ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.secondary : AppColors.outlineVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
