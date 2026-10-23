import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:viajeok/data/support_api.dart';

/// [HttpSupportApi] against a fake server that answers like the real
/// backend (`POST /api/support/tickets`).
void main() {
  late http.BaseRequest received;
  late String body;

  HttpSupportApi api(int status, String responseBody) => HttpSupportApi(
    Uri.parse('http://192.168.100.44:8010/api'),
    token: 'tok123',
    client: MockClient((request) async {
      received = request;
      body = request.body;
      return http.Response(responseBody, status);
    }),
  );

  final ticket = SupportTicket(
    issue: SupportIssue.wrongCalculation,
    sentAt: DateTime(2026, 10, 22, 13, 5, 9),
    email: 'chofer@correo.com',
    phoneModel: 'Realme 12',
  );

  test(
    'posts multipart to /api/support/tickets with the bearer token',
    () async {
      final receipt = await api(
        201,
        '{"id": "06bddd75", "folio": "SOP-000003"}',
      ).submit(ticket);

      expect(receipt.folio, 'SOP-000003');
      expect(receipt.id, '06bddd75');
      expect(received.method, 'POST');
      expect(
        received.url.toString(),
        'http://192.168.100.44:8010/api/support/tickets',
      );
      expect(received.headers['Authorization'], 'Bearer tok123');
      expect(
        received.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      expect(body, contains('name="issue"\r\n\r\nwrong_calculation'));
      expect(body, contains('name="email"\r\n\r\nchofer@correo.com'));
      expect(body, contains('name="phone_model"\r\n\r\nRealme 12'));
      expect(body, contains('name="device_time"'));
    },
  );

  test(
    'sends each screenshot as an "images" file with its image type',
    () async {
      final dir = await Directory.systemTemp.createTemp('support_test');
      addTearDown(() => dir.delete(recursive: true));
      final jpg = File('${dir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
      final png = File('${dir.path}/b.PNG')..writeAsBytesSync([4, 5, 6]);

      await api(201, '{"id": "1", "folio": "SOP-1"}').submit(
        SupportTicket(
          issue: SupportIssue.alertNotShown,
          sentAt: DateTime(2026),
          email: 'a@b.co',
          screenshotPaths: [jpg.path, png.path],
        ),
      );

      expect('name="images"'.allMatches(body).length, 2);
      expect(body, contains('content-type: image/jpeg'));
      expect(body, contains('content-type: image/png'));
    },
  );

  test('maps backend errors to what the form tells the user', () async {
    Future<SupportFailure> failureFor(int status, String responseBody) async {
      try {
        await api(status, responseBody).submit(ticket);
      } on SupportApiException catch (e) {
        return e.failure;
      }
      fail('expected an error for HTTP $status');
    }

    expect(
      await failureFor(429, '{"detail": "Demasiados reportes enviados"}'),
      SupportFailure.rateLimited,
    );
    expect(
      await failureFor(400, '{"issue": ["no es una elección válida."]}'),
      SupportFailure.invalid,
    );
    expect(
      await failureFor(401, '{"detail": "Token inválido"}'),
      SupportFailure.unavailable,
    );
    expect(await failureFor(500, 'boom'), SupportFailure.unavailable);
  });

  test('no connection is reported as unavailable', () async {
    final offline = HttpSupportApi(
      Uri.parse('http://192.168.100.44:8010/api'),
      token: 't',
      client: MockClient((_) => throw const SocketException('no route')),
    );
    expect(
      () => offline.submit(ticket),
      throwsA(
        isA<SupportApiException>().having(
          (e) => e.failure,
          'failure',
          SupportFailure.unavailable,
        ),
      ),
    );
  });

  test('a 201 without JSON still counts as sent', () async {
    final receipt = await api(201, '').submit(ticket);
    expect(receipt.folio, isNull);
  });
}
