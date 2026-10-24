import 'dart:math';

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

  // Billing state (lib/billing/): the last remote config and subscription
  // status, kept as JSON so the app works offline.
  static const _remoteConfigKey = 'remote_config';
  static const _entitlementKey = 'entitlement';
  static const _installIdKey = 'install_id';

  String? get remoteConfigJson => _prefs.getString(_remoteConfigKey);
  Future<void> setRemoteConfigJson(String json) =>
      _prefs.setString(_remoteConfigKey, json);

  String? get entitlementJson => _prefs.getString(_entitlementKey);
  Future<void> setEntitlementJson(String json) =>
      _prefs.setString(_entitlementKey, json);

  /// Random UUID v4 generated once per install; sent with purchase checks.
  Future<String> installId() async {
    final existing = _prefs.getString(_installIdKey);
    if (existing != null && existing.length == 36) return existing;
    final rnd = Random.secure();
    final b = List.generate(16, (_) => rnd.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await _prefs.setString(_installIdKey, id);
    return id;
  }
}
