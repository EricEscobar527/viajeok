import 'dart:io';

import 'package:flutter/services.dart';

/// App and phone details attached to support reports, read from Android
/// (`deviceInfo` on the `analisis_viaje/reader` channel in MainActivity.kt).
class DeviceInfo {
  const DeviceInfo({
    required this.appVersion,
    required this.appBuild,
    required this.androidVersion,
    required this.androidSdk,
    required this.manufacturer,
    required this.brand,
    required this.model,
  });

  /// e.g. "1.0.0" and 1 (pubspec `version: 1.0.0+1`).
  final String appVersion;
  final int appBuild;

  /// e.g. "16" and 36.
  final String androidVersion;
  final int androidSdk;

  /// e.g. "realme", "realme", "RMX5101".
  final String manufacturer;
  final String brand;
  final String model;

  static const _channel = MethodChannel('analisis_viaje/reader');

  /// Null off Android or if the details can't be read; reports are sent
  /// anyway, just without them.
  static Future<DeviceInfo?> load() async {
    if (!Platform.isAndroid) return null;
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('deviceInfo');
      if (m == null) return null;
      return DeviceInfo(
        appVersion: m['appVersion'] as String? ?? '',
        appBuild: (m['appBuild'] as num?)?.toInt() ?? 0,
        androidVersion: m['androidVersion'] as String? ?? '',
        androidSdk: (m['androidSdk'] as num?)?.toInt() ?? 0,
        manufacturer: m['manufacturer'] as String? ?? '',
        brand: m['brand'] as String? ?? '',
        model: m['model'] as String? ?? '',
      );
    } on PlatformException {
      return null;
    }
  }
}
