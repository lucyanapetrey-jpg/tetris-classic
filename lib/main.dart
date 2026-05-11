import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'i18n/app_strings.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/diamond_service.dart';
import 'services/locale_service.dart';
import 'services/purchase_service.dart';

Future<void> _requestATT() async {
  if (!Platform.isIOS) return;
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await Future.delayed(const Duration(milliseconds: 400));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestATT();
  await DiamondService().init();
  await LocaleService().init();
  await PurchaseService.instance.initialize();
  AdService().init();
  AudioService().init();
  runApp(const BlockSmileApp());
}

class BlockSmileApp extends StatelessWidget {
  const BlockSmileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocaleService(),
      builder: (context, _) {
        return MaterialApp(
          title: 'Block Smile',
          debugShowCheckedModeBanner: false,
          locale: LocaleService().locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppStrings.supportedLocales,
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: const Color(0xFF0D0D14),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00E5FF),
              brightness: Brightness.dark,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
