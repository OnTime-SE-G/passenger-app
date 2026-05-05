import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sceneCtl;
  late final AnimationController _fadeCtl;
  late final Animation<double> _fadeOut;

  static const double _busArriveEnd = 0.30;
  static const double _doorOpenEnd = 0.40;
  static const double _boardEnd = 0.55;
  static const double _doorCloseEnd = 0.65;
  static const double _departEnd = 0.90;

  static const double _kBusWidth = 180.0;
  static const double _kBusHeight = 80.0;

  @override
  void initState() {
    super.initState();

    _sceneCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _fadeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeCtl, curve: Curves.easeInCubic),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _sceneCtl.forward();
    _fadeCtl.forward();
    await _fadeCtl.forward().orCancel;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _sceneCtl.dispose();
    _fadeCtl.dispose();
    super.dispose();
  }

  double _busLeft(double screenW, double t) {
    final stopLeft = screenW * 0.5 - _kBusWidth / 2;

    if (t <= _busArriveEnd) {
      final u = Curves.easeOutCubic.transform(t / _busArriveEnd);
      return ui.lerpDouble(-_kBusWidth * 1.2, stopLeft, u)!;
    }
    if (t <= _doorCloseEnd) {
      return stopLeft;
    }
    if (t <= _departEnd) {
      final u = Curves.easeInCubic.transform(
          (t - _doorCloseEnd) / (_departEnd - _doorCloseEnd));
      return ui.lerpDouble(stopLeft, screenW + _kBusWidth * 0.5, u)!;
    }
    return screenW + _kBusWidth;
  }

  double _doorOpenProgress(double t) {
    if (t < _busArriveEnd) return 0.0;
    if (t < _doorOpenEnd) {
      return ((t - _busArriveEnd) / (_doorOpenEnd - _busArriveEnd)).clamp(0.0, 1.0);
    }
    if (t < _boardEnd) return 1.0;
    if (t < _doorCloseEnd) {
      return 1.0 - ((t - _boardEnd) / (_doorCloseEnd - _boardEnd)).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  ({double x, double opacity, double stride}) _passengerState(double screenW, double t) {
    final shelterX = screenW * 0.5 + 40.0;
    final busStopLeft = screenW * 0.5 - _kBusWidth / 2;
    // Door is roughly at 70% of bus width from left (front door)
    final doorX = busStopLeft + _kBusWidth * 0.75;

    if (t < _doorOpenEnd) {
      return (x: shelterX, opacity: 1.0, stride: 0.0);
    }
    if (t >= _doorCloseEnd) {
      return (x: doorX, opacity: 0.0, stride: 0.0);
    }

    final bt = ((t - _doorOpenEnd) / (_boardEnd - _doorOpenEnd)).clamp(0.0, 1.0);
    final curve = Curves.easeInOut.transform(bt);
    final x = ui.lerpDouble(shelterX, doorX, curve)!;
    final opacity = bt > 0.8 ? (1.0 - ((bt - 0.8) / 0.2)) : 1.0;
    final stride = math.sin(bt * math.pi * 8);

    return (x: x, opacity: opacity, stride: stride);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryFixed,
      body: AnimatedBuilder(
        animation: Listenable.merge([_sceneCtl, _fadeCtl]),
        builder: (_, __) {
          final t = _sceneCtl.value;
          final busLeft = _busLeft(size.width, t);
          final doorProgress = _doorOpenProgress(t);
          final pass = _passengerState(size.width, t);

          return Opacity(
            opacity: _fadeOut.value,
            child: Stack(
              children: [
                // Sky background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF7DD3FC), // Light sky blue
                          Color(0xFFE0F2FE),
                          Color(0xFFF1F5F9),
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                // Sun / Clouds
                Positioned(
                  top: size.height * 0.15,
                  right: size.width * 0.15,
                  child: const _SunWidget(),
                ),
                Positioned(
                  top: size.height * 0.25,
                  left: size.width * 0.1,
                  child: const _CloudWidget(width: 120, height: 40),
                ),
                Positioned(
                  top: size.height * 0.18,
                  right: size.width * 0.4,
                  child: const _CloudWidget(width: 80, height: 30, opacity: 0.6),
                ),

                // City skyline silhouette
                Positioned(
                  bottom: size.height * 0.35 + 20,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: const _Cityscape(),
                ),

                // Ground & Road
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.35,
                  child: Container(
                    color: const Color(0xFFD4D4D8), // Sidewalk area
                  ),
                ),
                Positioned(
                  bottom: size.height * 0.1,
                  left: 0,
                  right: 0,
                  height: size.height * 0.2,
                  child: CustomPaint(
                    painter: _PerspectiveRoadPainter(progress: t),
                  ),
                ),

                // Bus Stop Shelter
                Positioned(
                  bottom: size.height * 0.3,
                  left: size.width * 0.5 + 10,
                  width: 100,
                  height: 120,
                  child: const _BusStopShelter(),
                ),

                // Passenger
                if (pass.opacity > 0.01)
                  Positioned(
                    bottom: size.height * 0.3,
                    left: pass.x - 15,
                    child: Opacity(
                      opacity: pass.opacity,
                      child: SizedBox(
                        width: 30,
                        height: 50,
                        child: CustomPaint(
                          painter: _CharacterPainter(stride: pass.stride),
                        ),
                      ),
                    ),
                  ),

                // Bus
                Positioned(
                  bottom: size.height * 0.3 - 10,
                  left: busLeft,
                  child: SizedBox(
                    width: _kBusWidth,
                    height: _kBusHeight,
                    child: CustomPaint(
                      painter: _CinematicBusPainter(
                        primary: AppColors.primary,
                        accent: AppColors.secondary,
                        doorProgress: doorProgress,
                        isMoving: t < _busArriveEnd || t > _doorCloseEnd,
                        time: t,
                      ),
                    ),
                  ),
                ),

                // Top Logo
                Positioned(
                  top: size.height * 0.20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: t > 0.1 ? Curves.easeIn.transform(((t - 0.1) / 0.2).clamp(0.0, 1.0)) : 0.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Your City.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.2,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'On Time',
                            style: GoogleFonts.inter(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF2563EB),
                              letterSpacing: -1.0,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'PUBLIC TRANSPORT',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 2.0,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _SunWidget extends StatelessWidget {
  const _SunWidget();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFDE047),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFEF08A).withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 15,
          ),
        ],
      ),
    );
  }
}

class _CloudWidget extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;
  const _CloudWidget({required this.width, required this.height, this.opacity = 0.8});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

class _Cityscape extends StatelessWidget {
  const _Cityscape();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CityPainter(),
    );
  }
}

class _CityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCBD5E1).withOpacity(0.5);
    final random = math.Random(42);
    double x = 0;
    while (x < size.width) {
      final w = 30.0 + random.nextDouble() * 40.0;
      final h = 30.0 + random.nextDouble() * 80.0;
      canvas.drawRect(Rect.fromLTWH(x, size.height - h, w, h), paint);
      x += w + 5;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PerspectiveRoadPainter extends CustomPainter {
  final double progress;
  _PerspectiveRoadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Road Base
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64748B), Color(0xFF334155)],
        ).createShader(rect),
    );

    // Top and Bottom Curbs
    final curbPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 8), curbPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 8, size.width, 8), curbPaint);

    // Dashed Center Line (moving)
    final midY = size.height / 2;
    final dashPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final dashWidth = 40.0;
    final spaceWidth = 40.0;
    final totalWidth = dashWidth + spaceWidth;
    
    // Animate lines if progress indicates bus movement
    double offset = 0;
    if (progress < 0.3) {
       offset = (1.0 - progress / 0.3) * totalWidth * 5;
    } else if (progress > 0.65) {
       offset = ((progress - 0.65) / 0.35) * totalWidth * 10;
    }

    double x = -(offset % totalWidth) - dashWidth;
    while (x < size.width) {
      canvas.drawLine(Offset(x, midY), Offset(x + dashWidth, midY), dashPaint);
      x += totalWidth;
    }
  }
  @override
  bool shouldRepaint(covariant _PerspectiveRoadPainter oldDelegate) => oldDelegate.progress != progress;
}

class _BusStopShelter extends StatelessWidget {
  const _BusStopShelter();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ShelterPainter());
  }
}

class _ShelterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fill = Paint()..color = const Color(0xFFE2E8F0).withOpacity(0.9);
    final glass = Paint()..color = const Color(0xFFBAE6FD).withOpacity(0.4);

    // Back glass
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 20, 80, 90), const Radius.circular(8)), glass);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 20, 80, 90), const Radius.circular(8)), stroke);

    // Roof
    final roof = RRect.fromRectAndRadius(Rect.fromLTWH(0, 10, 100, 15), const Radius.circular(6));
    canvas.drawRRect(roof, fill);
    canvas.drawRRect(roof, stroke);

    // Pillars
    canvas.drawRect(Rect.fromLTWH(15, 25, 6, 95), fill);
    canvas.drawRect(Rect.fromLTWH(15, 25, 6, 95), stroke);
    canvas.drawRect(Rect.fromLTWH(79, 25, 6, 95), fill);
    canvas.drawRect(Rect.fromLTWH(79, 25, 6, 95), stroke);

    // Bus Stop Sign
    canvas.drawCircle(const Offset(90, -10), 12, Paint()..color = AppColors.secondary);
    canvas.drawCircle(const Offset(90, -10), 12, stroke);
    canvas.drawRect(Rect.fromLTWH(88, 2, 4, 18), stroke..style = PaintingStyle.fill);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CharacterPainter extends CustomPainter {
  final double stride;
  _CharacterPainter({required this.stride});

  @override
  void paint(Canvas canvas, Size size) {
    final ox = size.width / 2;
    final stroke = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Head
    canvas.drawCircle(Offset(ox, 10), 8, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawCircle(Offset(ox, 10), 8, stroke);

    // Body
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(ox - 8, 20, 16, 20), const Radius.circular(6));
    canvas.drawRRect(body, Paint()..color = AppColors.primary);
    canvas.drawRRect(body, stroke);

    // Legs
    final legSwing = stride * 6;
    final legPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ox - 3, 40), Offset(ox - 3 + legSwing, 50), legPaint);
    canvas.drawLine(Offset(ox + 3, 40), Offset(ox + 3 - legSwing, 50), legPaint);
  }
  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) => oldDelegate.stride != stride;
}

class _CinematicBusPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final double doorProgress;
  final bool isMoving;
  final double time;

  _CinematicBusPainter({
    required this.primary,
    required this.accent,
    required this.doorProgress,
    required this.isMoving,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    // Add tiny bounce when moving
    double bounceY = 0;
    if (isMoving) {
      bounceY = math.sin(time * 50) * 1.5;
    }

    canvas.save();
    canvas.translate(0, bounceY);

    final stroke = Paint()
      ..color = const Color(0xFF042F2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w/2, h), width: w * 0.9, height: 10),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main Body
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(5, 10, w - 10, h - 25),
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(24),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );
    canvas.drawRRect(body, Paint()..color = primary);
    
    // Bottom Stripe
    final stripe = RRect.fromRectAndCorners(
      Rect.fromLTWH(5, h - 35, w - 10, 10),
      bottomLeft: const Radius.circular(0),
      bottomRight: const Radius.circular(0),
    );
    canvas.drawRRect(stripe, Paint()..color = accent);
    canvas.drawRRect(body, stroke);

    // Windows
    final winRect = RRect.fromRectAndRadius(Rect.fromLTWH(15, 20, w - 30, 25), const Radius.circular(8));
    canvas.drawRRect(winRect, Paint()..color = const Color(0xFFBAE6FD));
    canvas.drawRRect(winRect, stroke);

    // Window Dividers
    for (double x = 40; x < w - 20; x += 30) {
      canvas.drawLine(Offset(x, 20), Offset(x, 45), stroke);
    }

    // Wheels
    void drawWheel(double cx, double cy) {
      canvas.drawCircle(Offset(cx, cy), 14, Paint()..color = const Color(0xFF111827));
      canvas.drawCircle(Offset(cx, cy), 14, stroke);
      canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = const Color(0xFF94A3B8));
    }
    drawWheel(35, h - 10);
    drawWheel(w - 40, h - 10);

    // Headlight
    canvas.drawCircle(Offset(w - 12, h - 25), 6, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(Offset(w - 12, h - 25), 6, stroke);

    // Taillight
    canvas.drawCircle(Offset(10, h - 25), 4, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(10, h - 25), 4, stroke);

    // Door Animation
    // Front door location
    final doorX = w * 0.75;
    final doorWidth = 22.0;
    
    // Door hole (dark interior)
    canvas.drawRect(Rect.fromLTWH(doorX - doorWidth/2, 20, doorWidth, h - 45), Paint()..color = const Color(0xFF0F172A));
    
    // Animated Doors (sliding open from center)
    final openAmount = doorProgress * (doorWidth / 2);
    final doorPaint = Paint()..color = primary.withOpacity(0.95);
    
    // Left door panel
    final leftDoor = Rect.fromLTWH(doorX - doorWidth/2 - openAmount, 20, doorWidth/2, h - 45);
    canvas.drawRect(leftDoor, doorPaint);
    canvas.drawRect(leftDoor, stroke..strokeWidth = 2);

    // Right door panel
    final rightDoor = Rect.fromLTWH(doorX + openAmount, 20, doorWidth/2, h - 45);
    canvas.drawRect(rightDoor, doorPaint);
    canvas.drawRect(rightDoor, stroke..strokeWidth = 2);

    // Exhaust Puff if moving fast (end of animation)
    if (isMoving && time > 0.7) {
      final puffScale = math.sin(time * 20).abs();
      canvas.drawCircle(
        Offset(-10 - puffScale * 10, h - 15), 
        8 + puffScale * 6, 
        Paint()..color = Colors.white.withOpacity(0.6)
      );
    }

    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _CinematicBusPainter oldDelegate) => 
    oldDelegate.doorProgress != doorProgress || oldDelegate.time != time;
}
