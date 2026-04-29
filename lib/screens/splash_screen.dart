import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/map_widgets.dart';
import 'app_shell.dart';

/// Splash: cartoon road, central bus stop, bus arrives → boards passenger → leaves.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sceneCtl;
  late final AnimationController _fadeCtl;
  late final AnimationController _mapZoomCtl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;
  late final Animation<double> _mapZoom;
  late final Animation<double> _mapOpacity;

  final _mapCtl = MapController();

  /// Story beats on one timeline [0,1]:
  /// ~0–0.26 arrive · ~0.26–0.40 dwell · ~0.40–0.56 board · ~0.56–1.0 depart
  static const double _arriveEnd = 0.26;
  static const double _dwellEnd = 0.40;
  static const double _boardEnd = 0.56;

  static const double _kBusLayoutW = 132.0;

  @override
  void initState() {
    super.initState();

    _sceneCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9200),
    );

    _mapZoomCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _mapZoom = Tween(begin: 12.0, end: 14.5).animate(
      CurvedAnimation(parent: _mapZoomCtl, curve: Curves.easeOut),
    );
    _mapOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mapZoomCtl, curve: const Interval(0.0, 0.28)),
    );

    _fadeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sceneCtl, curve: const Interval(0.0, 0.12)),
    );
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeCtl, curve: Curves.easeInCubic),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    _mapZoomCtl.forward();
    await Future.delayed(const Duration(milliseconds: 280));
    await _sceneCtl.forward();
    await Future.delayed(const Duration(milliseconds: 520));
    _fadeCtl.forward();
    await _fadeCtl.forward().orCancel;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionDuration: const Duration(milliseconds: 480),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _sceneCtl.dispose();
    _fadeCtl.dispose();
    _mapZoomCtl.dispose();
    super.dispose();
  }

  double _busLayoutLeft(double screenW, double t) {
    const busW = _kBusLayoutW;
    final roadInset = AppSpacing.lg;
    final roadMidX = roadInset + (screenW - 2 * roadInset) / 2;
    final stopLeft = roadMidX - busW / 2;

    if (t <= _arriveEnd) {
      final u = Curves.easeOutCubic.transform(t / _arriveEnd);
      final startLeft = -busW * 0.92;
      return ui.lerpDouble(startLeft, stopLeft, u)!;
    }
    if (t <= _boardEnd) {
      return stopLeft;
    }
    final u = Curves.easeInCubic.transform((t - _boardEnd) / (1.0 - _boardEnd));
    final exitLeft = screenW + busW * 0.45;
    return ui.lerpDouble(stopLeft, exitLeft, u)!;
  }

  /// Passenger walks shelter → door [dwellEnd, boardEnd].
  ({double x, double opacity}) _passengerAt(double screenW, double t) {
    final roadInset = AppSpacing.lg;
    final roadMid = roadInset + (screenW - 2 * roadInset) / 2;
    const busW = _kBusLayoutW;
    final stopLeft = roadMid - busW / 2;
    final doorX = stopLeft + 44;

    if (t < _dwellEnd) {
      return (x: roadMid - 48, opacity: t > 0.06 ? 1.0 : 0.0);
    }
    if (t >= _boardEnd) {
      return (x: doorX, opacity: 0.0);
    }
    final bt = Curves.easeInOut.transform(
      ((t - _dwellEnd) / (_boardEnd - _dwellEnd)).clamp(0.0, 1.0),
    );
    final startX = roadMid - 48;
    final x = ui.lerpDouble(startX, doorX, bt)!;
    final fadeBoard = bt > 0.72 ? (1.0 - ((bt - 0.72) / 0.28)).clamp(0.0, 1.0) : 1.0;
    return (x: x, opacity: fadeBoard);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_sceneCtl, _fadeCtl, _mapZoomCtl]),
        builder: (_, __) {
          // Must read scene progress inside this builder — outer `build` does not
          // run each animation tick, so a `t` captured there would stay at 0.0.
          final t = _sceneCtl.value;
          try {
            _mapCtl.move(
              const LatLng(12.9716, 77.5946),
              _mapZoom.value,
            );
          } catch (_) {}

          final busLeft = _busLayoutLeft(size.width, t);
          final pass = _passengerAt(size.width, t);

          return Opacity(
            opacity: _fadeOut.value,
            child: Stack(
              children: [
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

                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.05,
                      colors: [
                        Colors.white.withOpacity(0),
                        AppColors.primaryFixed.withOpacity(0.38),
                        AppColors.background.withOpacity(0.96),
                      ],
                      stops: const [0.0, 0.52, 1.0],
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Opacity(
                    opacity: (_fadeIn.value * 0.45).clamp(0.0, 0.45),
                    child: CustomPaint(
                      painter: _RouteLinesPainter(
                        progress: t,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Transform.translate(
                    offset: Offset(0, -size.height * 0.07),
                    child: Container(
                      width: 300,
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryContainer.withOpacity(0.18 * _fadeIn.value),
                            AppColors.secondary.withOpacity(0.05 * _fadeIn.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Road scene: asphalt + stop + bus + passenger
                Positioned(
                  bottom: size.height * 0.33,
                  left: 0,
                  right: 0,
                  height: 124,
                  child: Opacity(
                    opacity: _fadeIn.value,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: 0,
                          height: 56,
                          child: const _Road(),
                        ),
                        // Bus stop (center of road strip)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 8,
                          height: 72,
                          child: CustomPaint(
                            painter: _BusStopPainter(
                              roadInset: AppSpacing.lg,
                              screenWidth: size.width,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 14,
                          left: busLeft,
                          child: SizedBox(
                            width: _kBusLayoutW,
                            height: 58,
                            child: CustomPaint(
                              painter: _CartoonBusPainter(
                                primary: AppColors.primary,
                                accent: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                        if (pass.opacity > 0.02)
                          Positioned(
                            left: pass.x - 14,
                            bottom: 14,
                            child: Opacity(
                              opacity: pass.opacity,
                              child: SizedBox(
                                width: 28,
                                height: 42,
                                child: CustomPaint(
                                  painter: _CartoonPersonPainter(
                                    stride: t >= _dwellEnd && t < _boardEnd
                                        ? math.sin(
                                            ((t - _dwellEnd) /
                                                    (_boardEnd - _dwellEnd))
                                                .clamp(0.0, 1.0) *
                                                math.pi *
                                                14,
                                          )
                                        : 0.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: size.height * 0.09,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _fadeIn.value,
                    child: _LoadingDots(progress: t),
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

class _RouteLinesPainter extends CustomPainter {
  _RouteLinesPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.28)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.14)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = ui.Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.15,
        size.width * 0.55,
        size.height * 0.45,
        size.width * progress,
        size.height * 0.35,
      );

    final path2 = ui.Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.7,
        size.height * 0.65,
        size.width * 0.85 * progress,
        size.height * 0.5,
      );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, dashPaint);

    if (progress > 0.18) {
      final metrics1 = path1.computeMetrics().firstOrNull;
      if (metrics1 != null) {
        final pos = metrics1.getTangentForOffset(metrics1.length)?.position;
        if (pos != null) {
          canvas.drawCircle(pos, 4, Paint()..color = color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteLinesPainter old) =>
      old.progress != progress;
}

class _AsphaltRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF94A3B8),
            Color(0xFF64748B),
            Color(0xFF475569),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final outline = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, outline);

    final shoulder = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(12, 10), Offset(12, size.height - 10), shoulder);
    canvas.drawLine(
      Offset(size.width - 12, 10),
      Offset(size.width - 12, size.height - 10),
      shoulder,
    );

    final midY = size.height / 2;
    final dash = Paint()
      ..color = const Color(0xFFFDE047)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    var x = 18.0;
    while (x < size.width - 26) {
      canvas.drawLine(Offset(x, midY), Offset(x + 12, midY), dash);
      x += 24;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Road extends StatelessWidget {
  const _Road();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AsphaltRoadPainter(),
      child: const SizedBox.expand(),
    );
  }
}

/// Cartoon shelter + pole — bold outlines.
class _BusStopPainter extends CustomPainter {
  _BusStopPainter({required this.roadInset, required this.screenWidth});

  final double roadInset;
  final double screenWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = screenWidth / 2;
    final roofW = 64.0;
    final roofH = 28.0;
    final roofLeft = cx - roofW / 2;

    final roof = RRect.fromRectAndRadius(
      Rect.fromLTWH(roofLeft, 8, roofW, roofH),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      roof,
      Paint()..color = const Color(0xFFE2E8F0),
    );
    canvas.drawRRect(
      roof,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final pole = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 5, roofH + 6, 10, size.height - roofH - 6),
      const Radius.circular(4),
    );
    canvas.drawRRect(pole, Paint()..color = const Color(0xFF475569));
    canvas.drawRRect(
      pole,
      Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final sign = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 22, roofH + 2, 44, 18),
      const Radius.circular(6),
    );
    canvas.drawRRect(sign, Paint()..color = AppColors.secondary);
    canvas.drawRRect(
      sign,
      Paint()
        ..color = const Color(0xFF0E7490)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final busLabel = TextPainter(
      text: TextSpan(
        text: 'BUS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    busLabel.paint(canvas, Offset(cx - busLabel.width / 2, roofH + 5));
  }

  @override
  bool shouldRepaint(covariant _BusStopPainter oldDelegate) =>
      oldDelegate.screenWidth != screenWidth || oldDelegate.roadInset != roadInset;
}

/// Bold-outline cartoon coach — flat fills, readable shapes.
class _CartoonBusPainter extends CustomPainter {
  _CartoonBusPainter({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  static const stroke = Color(0xFF134E4A);
  static const ink = Color(0xFF042F2E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h - 5), width: w * 0.92, height: 10),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    void wheel(double cx, double cy) {
      canvas.drawCircle(Offset(cx, cy), 11, Paint()..color = const Color(0xFF111827));
      canvas.drawCircle(
        Offset(cx, cy),
        11,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        5,
        Paint()..color = const Color(0xFFE5E7EB),
      );
    }

    wheel(28, h - 12);
    wheel(w - 28, h - 12);

    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(5, 10, w - 10, 28),
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(12),
    );
    canvas.drawRRect(body, Paint()..color = accent);
    canvas.drawRRect(
      body,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final roofBump = RRect.fromRectAndRadius(
      Rect.fromLTWH(18, 5, w - 36, 14),
      const Radius.circular(10),
    );
    canvas.drawRRect(roofBump, Paint()..color = primary);
    canvas.drawRRect(
      roofBump,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final win = RRect.fromRectAndRadius(
      Rect.fromLTWH(14, 15, w - 52, 14),
      const Radius.circular(6),
    );
    canvas.drawRRect(win, Paint()..color = Colors.white);
    canvas.drawRRect(
      win,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final door = RRect.fromRectAndRadius(
      Rect.fromLTWH(38, 18, 22, 18),
      const Radius.circular(5),
    );
    canvas.drawRRect(door, Paint()..color = primary.withOpacity(0.92));
    canvas.drawRRect(
      door,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final hl = Paint()..color = const Color(0xFFFDE047);
    canvas.drawCircle(Offset(w - 18, h - 18), 5, hl);
    canvas.drawCircle(
      Offset(w - 18, h - 18),
      5,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(Offset(w - 31, h - 18), 5, hl);
    canvas.drawCircle(
      Offset(w - 31, h - 18),
      5,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final grin = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(22, 22), Offset(w - 56, 22), grin);
  }

  @override
  bool shouldRepaint(covariant _CartoonBusPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.accent != accent;
}

/// Tiny cartoon commuter — blob body + stride hint.
class _CartoonPersonPainter extends CustomPainter {
  _CartoonPersonPainter({required this.stride});

  final double stride;

  static const _inkDark = Color(0xFF1E293B);

  @override
  void paint(Canvas canvas, Size size) {
    final ox = size.width / 2;
    final headY = 10.0;
    canvas.drawCircle(
      Offset(ox, headY),
      8,
      Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(Offset(ox, headY), 7, Paint()..color = const Color(0xFFFDE68A));

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(ox, 26), width: 18, height: 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(torso, Paint()..color = AppColors.primary);
    canvas.drawRRect(
      torso,
      Paint()
        ..color = _inkDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final legSwing = stride * 3;
    final lp = Paint()
      ..color = _inkDark
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ox - 5, 34), Offset(ox - 7 + legSwing, 40), lp);
    canvas.drawLine(Offset(ox + 5, 34), Offset(ox + 7 - legSwing, 40), lp);
  }

  @override
  bool shouldRepaint(covariant _CartoonPersonPainter oldDelegate) =>
      oldDelegate.stride != stride;
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final threshold = (i + 1) / 4;
        final active = progress >= threshold;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: active ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.secondary : AppColors.outlineVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
