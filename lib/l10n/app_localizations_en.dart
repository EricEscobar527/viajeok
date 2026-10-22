// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String welcomeTitle(String appName) {
    return 'Welcome to\n$appName';
  }

  @override
  String get welcomeText =>
      'We tell you instantly whether a DiDi or Uber offer is worth it.';

  @override
  String get featureReadTitle => 'Reads every DiDi and Uber offer';

  @override
  String get featureReadText => 'Price, distance and time, hands-free';

  @override
  String get featureVerdictTitle => 'Green or red, instantly';

  @override
  String get featureVerdictText => 'Based on the minimums you set';

  @override
  String get featureOverlayTitle => 'Without leaving your app';

  @override
  String get featureOverlayText => 'A small notice on top of the offer';

  @override
  String get btnStart => 'Get started';

  @override
  String get supportTitle => 'Support';

  @override
  String get btnStartAnalysis => 'Start analysis';

  @override
  String get btnStopAnalysis => 'Stop analysis';

  @override
  String get panelHintIdle =>
      'Then open DiDi or Uber; we\'ll flag every offer.';

  @override
  String get panelRunning => 'Analyzing offers';

  @override
  String get panelHintRunning => 'Open DiDi or Uber and wait for your offers.';

  @override
  String get filtersTitle => 'My minimums';

  @override
  String get filtersSubtitle =>
      'An offer turns green if it meets every one you turn on.';

  @override
  String filtersActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count on',
      one: '1 on',
      zero: 'None on',
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
  String get dialogCancel => 'Not now';

  @override
  String get btnOpenSettings => 'Open settings';

  @override
  String get dialogEnableServiceTitle => 'Turn on Screen reading';

  @override
  String get dialogEnableServiceText =>
      'This is what lets the app read DiDi and Uber offers. You only turn it on once.\n\nIn Settings → Accessibility, find \"Análisis Viaje – Lectura de viajes\" and turn it on. Then come back and press Start.\n\nIf it shows as restricted: Settings → Apps → Análisis Viaje → ⋮ → Allow restricted settings.';

  @override
  String get supportIssueLabel => 'What\'s the problem?';

  @override
  String get supportIssueWrongCalculation => 'The calculations are wrong';

  @override
  String get supportIssueAlertNotShown =>
      'The alert doesn\'t show in DiDi or Uber even though Análisis Viaje is on';

  @override
  String get supportIssueOther => 'Another problem';

  @override
  String get supportIssueRequired => 'Choose what the problem is';

  @override
  String get supportPhoneModel => 'Phone model';

  @override
  String get supportPhoneModelHint => 'e.g. Samsung Galaxy A54';

  @override
  String get supportScreenshots => 'Screenshots';

  @override
  String get supportAddScreenshot => 'Add';

  @override
  String get supportRemoveScreenshot => 'Remove screenshot';

  @override
  String supportScreenshotsHint(int max) {
    return 'Up to $max images. They help us find the problem faster.';
  }

  @override
  String get supportEmail => 'Email';

  @override
  String get supportEmailHint => 'you@example.com';

  @override
  String get supportEmailInvalid => 'Enter a valid email';

  @override
  String get supportDescription => 'What happened?';

  @override
  String get supportDescriptionHint => 'Tell us what happened';

  @override
  String get supportFieldRequired => 'This field is required';

  @override
  String get supportSend => 'Send';

  @override
  String get supportSending => 'Sending…';

  @override
  String get supportSendError =>
      'Couldn\'t send it. Check your connection and try again.';

  @override
  String get supportSentTitle => 'We\'re reviewing the information';

  @override
  String get supportSentText => 'The average response time is 12 hours.';

  @override
  String get supportSentOk => 'Got it';

  @override
  String get serviceOnTitle => 'Screen reading is on';

  @override
  String get serviceOnText =>
      'If a banking app won\'t let you in, turn it off here.';

  @override
  String get btnDisableService => 'Turn off';

  @override
  String get dialogDisableServiceTitle => 'Turn off Screen reading?';

  @override
  String get dialogDisableServiceText =>
      'Some banking apps (like Nu) won\'t open while it\'s on. Turning it off also stops the analysis.\n\nTo use it again, press Start analysis and turn it back on in Settings.';

  @override
  String get serviceDisabledNotice =>
      'Screen reading is off. You can open your banking app now.';

  @override
  String supportSentFolio(String folio) {
    return 'Your ticket number is $folio.';
  }

  @override
  String get supportSendRateLimited =>
      'You\'ve sent too many reports. Try again later.';

  @override
  String get supportSendInvalid =>
      'Couldn\'t send it: check the details and images.';

  @override
  String get supportImageFormat =>
      'Some images weren\'t added: use JPG or PNG screenshots.';
}
