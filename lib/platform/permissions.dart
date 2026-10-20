import 'dart:io';

import 'package:flutter/services.dart';

/// Bridge to the Android-side handler in MainActivity.kt.
abstract final class Permissions {
  static const _channel = MethodChannel('analisis_viaje/permissions');

  /// "Display over other apps" (SYSTEM_ALERT_WINDOW). Always true off Android.
  static Future<bool> canDrawOverlays() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
  }

  static Future<void> openOverlaySettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('openOverlaySettings');
  }
}
