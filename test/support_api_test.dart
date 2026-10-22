import 'package:flutter_test/flutter_test.dart';

import 'package:analisis_viaje/data/support_api.dart';
import 'package:analisis_viaje/platform/device_info.dart';

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
    expect(fields.containsKey('description'), isFalse);
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
      description: 'Algo pasó',
    ).toFormFields();

    expect(fields.keys, {'issue', 'email', 'description', 'device_time'});
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
}
