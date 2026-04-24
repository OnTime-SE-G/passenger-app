import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Work done while the splash is visible. Splash stays until this finishes and
/// the minimum display time has passed (whichever is longer).
class AppBootstrap {
  AppBootstrap._();

  static Future<void>? _ready;

  static Future<void> ensureReady() {
    _ready ??= _run();
    return _ready!;
  }

  static Future<void> _run() async {
    // Queue Google Font loads (especially slow on web); then wait for them.
    GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900);
    GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600);
    GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w400);
    GoogleFonts.manrope(fontWeight: FontWeight.w700);
    GoogleFonts.manrope(fontWeight: FontWeight.w600);
    GoogleFonts.manrope(fontWeight: FontWeight.w400);
    await GoogleFonts.pendingFonts();

    await rootBundle.load('splash_image.png');
  }
}
