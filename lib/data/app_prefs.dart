import 'package:shared_preferences/shared_preferences.dart';

import 'trip_filters.dart';

/// Small persisted settings. Load once with [AppPrefs.load] at startup.
class AppPrefs {
  AppPrefs._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> load() async =>
      AppPrefs._(await SharedPreferences.getInstance());

  static const _onboardingDoneKey = 'onboarding_done';

  bool get onboardingDone => _prefs.getBool(_onboardingDoneKey) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_onboardingDoneKey, true);

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
