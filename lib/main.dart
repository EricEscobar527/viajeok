import 'dart:async';

import 'package:flutter/material.dart';

import 'app_info.dart';
import 'data/app_prefs.dart';
import 'home/home_shell.dart';
import 'l10n/app_localizations.dart';
import 'onboarding/onboarding_screen.dart';
import 'platform/trip_reader.dart';
import 'splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefs.load();
  // The native service keeps its own copy of the filters; resync on launch.
  unawaited(TripReader.pushConfig(prefs));
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Mexico-only launch: always Spanish. app_en.arb is kept for later.
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: SplashScreen(next: _AfterSplash(prefs: prefs)),
    );
  }
}

/// Onboarding on first launch, the home panel every time after that.
class _AfterSplash extends StatefulWidget {
  const _AfterSplash({required this.prefs});

  final AppPrefs prefs;

  @override
  State<_AfterSplash> createState() => _AfterSplashState();
}

class _AfterSplashState extends State<_AfterSplash> {
  late bool _onboarded = widget.prefs.onboardingDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _onboarded
          ? HomeShell(prefs: widget.prefs)
          : OnboardingScreen(
              prefs: widget.prefs,
              onFinished: () => setState(() => _onboarded = true),
            ),
    );
  }
}
