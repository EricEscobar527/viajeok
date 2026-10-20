import 'package:shared_preferences/shared_preferences.dart';

import 'trip_filters.dart';

enum RideApp {
  uber('Uber'),
  didi('DiDi'),
  indrive('inDrive'),
  bolt('Bolt');

  const RideApp(this.label);

  final String label;
}

/// Small persisted settings. Load once with [AppPrefs.load] at startup.
class AppPrefs {
  AppPrefs._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> load() async =>
      AppPrefs._(await SharedPreferences.getInstance());

  static const _onboardingDoneKey = 'onboarding_done';
  static const _appsKey = 'monitored_apps';

  bool get onboardingDone => _prefs.getBool(_onboardingDoneKey) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_onboardingDoneKey, true);

  Set<RideApp> get monitoredApps {
    final names = _prefs.getStringList(_appsKey);
    if (names == null) return {RideApp.uber, RideApp.didi};
    return {
      for (final a in RideApp.values)
        if (names.contains(a.name)) a,
    };
  }

  Future<void> setMonitoredApps(Set<RideApp> apps) =>
      _prefs.setStringList(_appsKey, [for (final a in apps) a.name]);

  // Filters are stored as `filter_<kind>_on` / `filter_<kind>_value`.
  List<TripFilter> get filters => [
    for (final k in FilterKind.values)
      TripFilter(
        kind: k,
        enabled: _prefs.getBool('filter_${k.name}_on') ?? false,
        value: _prefs.getDouble('filter_${k.name}_value') ?? k.defaultValue,
      ),
  ];

  Future<void> setFilter(TripFilter f) async {
    await _prefs.setBool('filter_${f.kind.name}_on', f.enabled);
    await _prefs.setDouble('filter_${f.kind.name}_value', f.value);
  }
}
