import 'dart:io';

import 'package:flutter/services.dart';

import '../data/app_prefs.dart';

/// Native package names of the ride driver apps.
const rideAppPackages = {
  RideApp.uber: 'com.ubercab.driver',
  RideApp.didi: 'com.didiglobal.driver',
  RideApp.indrive: 'sinet.startup.inDriver',
  RideApp.bolt: 'ee.mtakso.driver',
};

class TripStats {
  const TripStats(this.total, this.accepted, this.rejected);

  static const zero = TripStats(0, 0, 0);

  final int total;
  final int accepted;
  final int rejected;
}

/// Bridge to TripReaderService.kt over the `analisis_viaje/reader` channel.
/// Parsing, filtering and the popup all happen natively, so they keep
/// working while this app is in the background.
abstract final class TripReader {
  static const _channel = MethodChannel('analisis_viaje/reader');

  /// Whether the user turned the accessibility service on in Android settings.
  static Future<bool> isServiceEnabled() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('isServiceEnabled') ?? false;
  }

  static Future<void> openServiceSettings() =>
      _channel.invokeMethod<void>('openServiceSettings');

  /// Sends the current filters and monitored apps to the native side.
  static Future<void> pushConfig(AppPrefs prefs) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setConfig', {
      'packages': [for (final a in prefs.monitoredApps) rideAppPackages[a]!],
      'filters': [
        for (final f in prefs.filters)
          {'kind': f.kind.name, 'enabled': f.enabled, 'value': f.value},
      ],
    });
  }

  static Future<bool> isRunning() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('isRunning') ?? false;
  }

  /// Starting resets the session counters.
  static Future<void> setRunning(bool running) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setRunning', running);
  }

  static Future<TripStats> stats() async {
    if (!Platform.isAndroid) return TripStats.zero;
    final m = await _channel.invokeMapMethod<String, int>('getStats') ?? {};
    return TripStats(m['total'] ?? 0, m['accepted'] ?? 0, m['rejected'] ?? 0);
  }
}
