import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  // Suppress harmless web startup discard warnings by increasing the buffer size
  ui.channelBuffers.resize('flutter/lifecycle', 100);
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PassengerApp());
}

class PassengerApp extends StatelessWidget {
  const PassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnTime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(context),
      home: const SplashScreen(),
    );
  }
}
