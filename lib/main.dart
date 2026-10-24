import 'dart:async';

import 'package:flutter/material.dart';

import 'app_info.dart';
import 'billing/billing_api.dart';
import 'billing/store.dart';
import 'billing/subscription_controller.dart';
import 'billing/update_required_screen.dart';
import 'data/app_prefs.dart';
import 'home/home_shell.dart';
import 'l10n/app_localizations.dart';
import 'onboarding/onboarding_screen.dart';
import 'platform/device_info.dart';
import 'platform/trip_reader.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefs.load();
  // The native service keeps its own copy of the filters; resync on launch.
  unawaited(TripReader.pushConfig(prefs));
  final subscriptions = SubscriptionController(
    prefs: prefs,
    backend: BillingBackend.create(),
    store: GooglePlayStore(),
    appBuild: (await DeviceInfo.load())?.appBuild,
  );
  unawaited(subscriptions.start());
  runApp(MyApp(prefs: prefs, subscriptions: subscriptions));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs, required this.subscriptions});

  final AppPrefs prefs;
  final SubscriptionController subscriptions;

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
      home: ListenableBuilder(
        listenable: subscriptions,
        builder: (context, _) => subscriptions.updateRequired
            ? const UpdateRequiredScreen()
            : _Start(prefs: prefs, subscriptions: subscriptions),
      ),
    );
  }
}

/// Onboarding on first launch, the home panel every time after that.
class _Start extends StatefulWidget {
  const _Start({required this.prefs, required this.subscriptions});

  final AppPrefs prefs;
  final SubscriptionController subscriptions;

  @override
  State<_Start> createState() => _StartState();
}

class _StartState extends State<_Start> {
  late bool _onboarded = widget.prefs.onboardingDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _onboarded
          ? HomeShell(prefs: widget.prefs, subscriptions: widget.subscriptions)
          : OnboardingScreen(
              prefs: widget.prefs,
              onFinished: () => setState(() => _onboarded = true),
            ),
    );
  }
}
