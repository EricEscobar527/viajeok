import 'dart:io';

import 'package:flutter/services.dart';

/// State of the trip reader on this phone, attached to support reports so
/// "the alert doesn't show" can be diagnosed without asking the driver
/// (`diagnostics` on the `viajeok/reader` channel in MainActivity.kt).
/// Times only, never anything an offer said.
class ReaderDiagnostics {
  const ReaderDiagnostics({
    required this.serviceEnabled,
    required this.serviceConnected,
    required this.running,
    required this.locked,
    required this.batteryUnrestricted,
    required this.backgroundRestricted,
    required this.powerSave,
    this.didi,
    this.uber,
    this.rappi,
    this.lastRideApp,
    this.lastRideAppAt,
    this.lastOfferAt,
  });

  /// "Lectura de pantalla" switched on in Android's accessibility settings.
  final bool serviceEnabled;

  /// Android actually started it (enabled but not connected = killed).
  final bool serviceConnected;

  /// ▶ "Iniciar análisis" is on.
  final bool running;

  /// Analysis stopped by the subscription lock.
  final bool locked;

  /// Exempt from battery optimization ("Sin restricciones").
  final bool batteryUnrestricted;

  /// The user restricted the app's background use.
  final bool backgroundRestricted;

  /// Battery saver is on.
  final bool powerSave;

  /// Installed versions; null = not installed.
  final String? didi;
  final String? uber;
  final String? rappi;

  /// Package of the ride app the service last saw in front, and when.
  final String? lastRideApp;
  final DateTime? lastRideAppAt;

  /// When the service last read an offer.
  final DateTime? lastOfferAt;

  static const _channel = MethodChannel('viajeok/reader');

  /// Null off Android or if they can't be read; reports go out anyway.
  static Future<ReaderDiagnostics?> load() async {
    if (!Platform.isAndroid) return null;
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('diagnostics');
      return m == null ? null : ReaderDiagnostics.fromMap(m);
    } on PlatformException {
      return null;
    }
  }

  factory ReaderDiagnostics.fromMap(Map<String, Object?> m) {
    DateTime? time(String key) {
      final ms = (m[key] as num?)?.toInt() ?? 0;
      return ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    }

    return ReaderDiagnostics(
      serviceEnabled: m['serviceEnabled'] == true,
      serviceConnected: m['serviceConnected'] == true,
      running: m['running'] == true,
      locked: m['locked'] == true,
      batteryUnrestricted: m['batteryUnrestricted'] == true,
      backgroundRestricted: m['backgroundRestricted'] == true,
      powerSave: m['powerSave'] == true,
      didi: m['didi'] as String?,
      uber: m['uber'] as String?,
      rappi: m['rappi'] as String?,
      lastRideApp: m['lastRideApp'] as String?,
      lastRideAppAt: time('lastRideAppAt'),
      lastOfferAt: time('lastOfferAt'),
    );
  }

  static const _appNames = {
    'com.didiglobal.driver': 'DiDi',
    'com.ubercab.driver': 'Uber',
    'com.rappi.storekeeper': 'Rappi',
  };

  /// Plain-text block for the support team (sent in the report, not shown
  /// in the app, so it isn't localized).
  String describe(DateTime now) {
    String yesNo(bool v) => v ? 'sí' : 'NO';
    String ago(DateTime? t) {
      if (t == null) return 'nunca';
      final d = now.difference(t);
      if (d.inMinutes < 1) return 'hace menos de 1 min';
      if (d.inHours < 1) return 'hace ${d.inMinutes} min';
      if (d.inDays < 1) return 'hace ${d.inHours} h';
      return 'hace ${d.inDays} días';
    }

    String app(String name, String? version) =>
        '$name ${version ?? 'no instalada'}';
    final seen = lastRideApp == null
        ? 'nunca'
        : '${_appNames[lastRideApp] ?? lastRideApp}, ${ago(lastRideAppAt)}';

    return [
      '--- Diagnóstico automático ---',
      'Lectura de pantalla activada: ${yesNo(serviceEnabled)}'
          '${serviceEnabled && !serviceConnected ? ' (pero Android no la está ejecutando)' : ''}',
      'Análisis encendido (Iniciar análisis): ${yesNo(running)}'
          '${locked ? ' (bloqueado por suscripción)' : ''}',
      'Batería sin restricciones: ${yesNo(batteryUnrestricted)}'
          '${backgroundRestricted ? ' · segundo plano RESTRINGIDO' : ''}'
          '${powerSave ? ' · ahorro de batería encendido' : ''}',
      'Apps: ${app('DiDi', didi)} · ${app('Uber', uber)} · ${app('Rappi', rappi)}',
      'Última app de viajes vista: $seen',
      'Última oferta leída: ${ago(lastOfferAt)}',
    ].join('\n');
  }
}
