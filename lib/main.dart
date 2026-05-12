import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui' as ui;

import 'data/api_repository.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Suppress harmless web startup discard warnings by increasing the buffer size
  ui.channelBuffers.resize('flutter/lifecycle', 100);
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/mapbox.env');
  // Pre-load stops, routes, and buses from the API.
  unawaited(ApiRepository.instance.initialize());
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
