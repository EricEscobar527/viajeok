// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get btnSetupNow => 'Set up now';

  @override
  String get btnNext => 'Next';

  @override
  String get btnOpenSettings => 'Open settings';

  @override
  String get btnStartEarning => 'Start earning!';

  @override
  String welcomeTitle(String appName) {
    return 'Welcome to\n$appName!';
  }

  @override
  String get welcomeText =>
      'Let\'s set it up in 1 minute\nso it works perfectly while you drive.';

  @override
  String get featureTripAnalysis => 'Every trip analyzed';

  @override
  String get featureInYourApps => 'In your favorite ride apps';

  @override
  String get featurePopupOverApp => 'Popup over your ride app';

  @override
  String get featureWithoutLeaving => 'Without leaving your work app';

  @override
  String get featureGreenRed => 'Green or red, instantly';

  @override
  String get featureByFilters => 'Based on your earning filters';

  @override
  String get overlayTitle => 'Display over apps';

  @override
  String get overlayText =>
      'Lets the earnings popup appear on top of your ride apps while you drive, without switching apps.';

  @override
  String get overlayGranted => 'Permission granted — the popup can appear.';

  @override
  String get overlayRequired =>
      'This permission is required. Without it, the popup can\'t appear.';

  @override
  String get overlayPreviewTitle => 'This is how it looks while you drive:';

  @override
  String get overlayPreviewText =>
      '← Turns green if the trip is worth it and red if not, based on your filters.';

  @override
  String get doneTitle => 'All set!';

  @override
  String doneText(String appName) {
    return '$appName is set up.\nPress ► Play and start analyzing your trips.';
  }

  @override
  String get featureAutoAnalysis => 'Automatic trip analysis';

  @override
  String get featurePopupOverApps => 'Popup over your apps';

  @override
  String get featureWhileDriving => 'Works while you drive';

  @override
  String get tabHome => 'Home';

  @override
  String get tabConfig => 'Settings';

  @override
  String get tabSupport => 'Support';

  @override
  String get supportText => 'Help and contact. Coming soon.';

  @override
  String get panelReady => 'Ready to start';

  @override
  String get panelRunning => 'Analyzing trips…';

  @override
  String get panelTapToStart => 'Tap to start the analysis';

  @override
  String get panelTapToStop => 'Tap to stop the analysis';

  @override
  String get statTotal => 'Total';

  @override
  String get statAccept => 'Accept';

  @override
  String get statReject => 'Reject';

  @override
  String get filtersTitle => 'Smart filters';

  @override
  String filtersActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active',
      one: '1 active',
    );
    return '$_temp0';
  }

  @override
  String get filterPerHour => 'Per hour';

  @override
  String get filterPerKm => 'Per km';

  @override
  String get filterMaxPickup => 'Max pickup';

  @override
  String get filterPerHourHint =>
      'Minimum earnings per hour, including the time to pick up.';

  @override
  String get filterPerKmHint =>
      'Minimum earnings per km, including the km to pick up.';

  @override
  String get filterMaxPickupHint =>
      'Maximum distance you drive unpaid to pick up.';

  @override
  String filterMaxPickupValue(String value) {
    return '$value km max';
  }

  @override
  String get filterOff => 'Off';

  @override
  String get configAppsTitle => 'Monitored apps';

  @override
  String get configAppsSubtitle => 'Tap to turn the calculation on or off';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogEnableServiceTitle => 'Turn on Screen reading';

  @override
  String get dialogEnableServiceText =>
      'In Settings → Accessibility, find \"Análisis Viaje – Lectura de viajes\" and turn it on. Then come back and press ▶.\n\nIf it shows as restricted: Settings → Apps → Análisis Viaje → ⋮ → Allow restricted settings.';

  @override
  String get readingTitle => 'Screen reading';

  @override
  String readingText(String appName) {
    return '$appName reads the price and distance of each offer in DiDi and Uber to tell you if it is worth it. Turn it on once and it keeps working even when you lock your phone.';
  }

  @override
  String get readingEnabled => 'Screen reading is on — all set.';

  @override
  String get readingRequired =>
      'This permission is required. Without it, the app can\'t read offers.';
}
