import 'package:flutter_test/flutter_test.dart';

import 'package:viajeok/data/support_api.dart';
import 'package:viajeok/platform/device_info.dart';
import 'package:viajeok/platform/reader_diagnostics.dart';

void main() {
  const device = DeviceInfo(
    appVersion: '1.0.0',
    appBuild: 1,
    androidVersion: '16',
    androidSdk: 36,
    manufacturer: 'realme',
    brand: 'realme',
    model: 'RMX5101',
  );

  test('sends what the user typed plus the automatic details', () {
    final ticket = SupportTicket(
      issue: SupportIssue.wrongCalculation,
      sentAt: DateTime(2026, 10, 22, 13, 5, 9),
      email: 'chofer@correo.com',
      phoneModel: 'Realme 12',
      device: device,
    );
    final fields = ticket.toFormFields();

    expect(fields['issue'], 'wrong_calculation');
    expect(fields['email'], 'chofer@correo.com');
    expect(fields['phone_model'], 'Realme 12');
    expect(fields.containsKey('message'), isFalse);
    expect(fields['app_version'], '1.0.0');
    expect(fields['app_build'], '1');
    expect(fields['android_version'], '16');
    expect(fields['android_sdk'], '36');
    expect(fields['device_manufacturer'], 'realme');
    expect(fields['device_brand'], 'realme');
    expect(fields['device_model'], 'RMX5101');
    expect(fields['device_time'], startsWith('2026-10-22T13:05:09'));
  });

  test('still sends the report when device details are unavailable', () {
    final fields = SupportTicket(
      issue: SupportIssue.other,
      sentAt: DateTime(2026, 1, 2, 3, 4, 5),
      email: 'a@b.co',
      message: 'Algo pasó',
    ).toFormFields();

    expect(fields.keys, {'issue', 'email', 'message', 'device_time'});
  });

  test('message carries the comment, ride app and diagnostics', () {
    final now = DateTime(2026, 11, 25, 12);
    final diag = ReaderDiagnostics.fromMap({
      'serviceEnabled': true,
      'serviceConnected': false,
      'running': true,
      'locked': false,
      'batteryUnrestricted': false,
      'backgroundRestricted': true,
      'powerSave': false,
      'didi': null,
      'uber': '4.512.10001',
      'rappi': null,
      'lastRideApp': 'com.ubercab.driver',
      'lastRideAppAt': now
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch,
      'lastOfferAt': 0,
    });
    final message = SupportTicket(
      issue: SupportIssue.alertNotShown,
      sentAt: now,
      message: 'No sale nada',
      rideApp: RideApp.uber,
      diagnostics: diag,
    ).toFormFields()['message']!;

    expect(message, startsWith('No sale nada\n\nApp de viajes: Uber\n\n'));
    expect(
      message,
      contains(
        'Lectura de pantalla activada: sí (pero Android no la está ejecutando)',
      ),
    );
    expect(message, contains('Análisis encendido (Iniciar análisis): sí'));
    expect(
      message,
      contains('Batería sin restricciones: NO · segundo plano RESTRINGIDO'),
    );
    expect(
      message,
      contains(
        'Apps: DiDi no instalada · Uber 4.512.10001 · Rappi no instalada',
      ),
    );
    expect(message, contains('Última app de viajes vista: Uber, hace 5 min'));
    expect(message, contains('Última oferta leída: nunca'));
  });

  test('no message field when there is nothing to say', () {
    final fields = SupportTicket(
      issue: SupportIssue.wrongCalculation,
      sentAt: DateTime(2026),
      email: 'a@b.co',
    ).toFormFields();
    expect(fields.containsKey('message'), isFalse);
  });

  test('device time carries the UTC offset', () {
    final local = DateTime(2026, 10, 22, 13, 5, 9);
    expect(
      isoWithOffset(local),
      matches(RegExp(r'^2026-10-22T13:05:09[+-]\d{2}:\d{2}$')),
    );
    expect(
      isoWithOffset(DateTime.utc(2026, 10, 22, 19, 5, 9)),
      '2026-10-22T19:05:09+00:00',
    );
  });

  test('a build without the API config never pretends a report was sent', () {
    expect(
      () => const UnconfiguredSupportApi().submit(
        SupportTicket(issue: SupportIssue.other, sentAt: DateTime(2026)),
      ),
      throwsA(isA<SupportApiException>()),
    );
  });
}
