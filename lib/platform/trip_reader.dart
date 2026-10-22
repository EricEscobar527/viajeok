import 'dart:io';

import 'package:flutter/services.dart';

import '../data/app_prefs.dart';

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

  /// Turns the accessibility service off (and stops the analysis), e.g. so
  /// a banking app that blocks accessibility services will open. Returns
  /// true if it was turned off directly, false if Android's accessibility
  /// settings were opened for the user to do it.
  static Future<bool> disableService() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('disableService') ?? false;
  }

  /// Sends the current filters to the native side.
  static Future<void> pushConfig(AppPrefs prefs) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setConfig', {
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

  static Future<void> setRunning(bool running) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setRunning', running);
  }
}
