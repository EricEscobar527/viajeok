import 'dart:io';

import 'package:flutter/services.dart';

import '../data/app_prefs.dart';

/// Bridge to TripReaderService.kt over the `viajeok/reader` channel.
/// Parsing, filtering and the popup all happen natively, so they keep
/// working while this app is in the background.
abstract final class TripReader {
  static const _channel = MethodChannel('viajeok/reader');

  /// Whether the user turned the accessibility service on in Android settings.
  static Future<bool> isServiceEnabled() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('isServiceEnabled') ?? false;
  }

  static Future<void> openServiceSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('openServiceSettings');
  }

  /// Turns the accessibility service off (and stops the analysis), e.g. so
  /// a banking app that blocks accessibility services will open. Returns
  /// true if it was turned off directly, false if Android's accessibility
  /// settings were opened for the user to do it.
  static Future<bool> disableService() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('disableService') ?? false;
  }

  /// Sends the current filters and popup labels to the native side.
  static Future<void> pushConfig(AppPrefs prefs) async {
    if (!Platform.isAndroid) return;
    List<String> texts(bool accept) => [
      for (final t in prefs.labels(accept: accept))
        if (t.trim().isNotEmpty) t.trim(),
    ];
    await _channel.invokeMethod<void>('setConfig', {
      'filters': [
        for (final f in prefs.filters)
          {'kind': f.kind.name, 'enabled': f.enabled, 'value': f.value},
      ],
      'labels': {
        'enabled': prefs.labelsEnabled,
        'accept': texts(true),
        'reject': texts(false),
      },
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

  /// Analysis stops by itself after [at] (null = never), so a lapsed
  /// subscription stops even if this app isn't opened again.
  static Future<void> setLockAt(DateTime? at) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>(
      'setLockAt',
      at?.millisecondsSinceEpoch ?? 0,
    );
  }

  /// Opens [url] in whatever app handles it; false if none can.
  static Future<bool> openUrl(String url) async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('openUrl', url) ?? false;
  }
}
