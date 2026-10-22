import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../platform/device_info.dart';

/// What the user picked in "¿Qué problema tienes?". The [code] is what the
/// backend receives, so keep it stable even if the labels change.
enum SupportIssue {
  wrongCalculation('wrong_calculation'),
  alertNotShown('alert_not_shown'),
  other('other');

  const SupportIssue(this.code);

  final String code;

  /// Calculation and alert problems need device details and screenshots to
  /// reproduce; "other" is a free-text description. All of them ask for an
  /// email so the report can be answered.
  bool get needsDeviceDetails => this != SupportIssue.other;
}

/// A support report: what the user filled in, plus app/phone details
/// collected automatically.
class SupportTicket {
  const SupportTicket({
    required this.issue,
    required this.sentAt,
    this.phoneModel,
    this.email,
    this.description,
    this.screenshotPaths = const [],
    this.device,
  });

  final SupportIssue issue;

  /// The phone's local date/time when the report was sent.
  final DateTime sentAt;

  /// As typed by the user.
  final String? phoneModel;
  final String? email;
  final String? description;

  /// Local file paths of the screenshots the user picked.
  final List<String> screenshotPaths;

  /// App version, Android version and brand/model as Android reports them.
  /// Null if they couldn't be read.
  final DeviceInfo? device;

  /// Text fields of the multipart request (see [HttpSupportApi]).
  Map<String, String> toFormFields() => {
    'issue': issue.code,
    'email': ?email,
    'phone_model': ?phoneModel,
    'description': ?description,
    'device_time': isoWithOffset(sentAt),
    if (device case final d?) ...{
      'app_version': d.appVersion,
      'app_build': '${d.appBuild}',
      'android_version': d.androidVersion,
      'android_sdk': '${d.androidSdk}',
      'device_manufacturer': d.manufacturer,
      'device_brand': d.brand,
      'device_model': d.model,
    },
  };
}

/// "2026-10-22T13:05:09-06:00": local time with its UTC offset, so the
/// backend knows both the user's clock and the real instant.
String isoWithOffset(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  final offset = t.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final abs = offset.abs();
  return '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)}'
      'T${two(t.hour)}:${two(t.minute)}:${two(t.second)}'
      '$sign${two(abs.inHours)}:${two(abs.inMinutes % 60)}';
}

class SupportApiException implements Exception {
  const SupportApiException(this.message);

  final String message;

  @override
  String toString() => 'SupportApiException: $message';
}

/// Sends support reports. Swap the implementation in [SupportApi.create]
/// once the backend exists; the form only depends on this interface.
abstract interface class SupportApi {
  Future<void> submit(SupportTicket ticket);

  /// The API the app uses: the real backend when [SupportApiConfig.baseUrl]
  /// is set, otherwise a stand-in that accepts every report.
  factory SupportApi.create() => SupportApiConfig.baseUrl.isEmpty
      ? const PendingSupportApi()
      : HttpSupportApi(Uri.parse(SupportApiConfig.baseUrl));
}

/// Backend settings. Fill these in when the API is ready.
abstract final class SupportApiConfig {
  /// e.g. 'https://api.example.com'. Empty = backend not available yet.
  static const baseUrl = '';

  /// Path of the endpoint that receives reports.
  static const ticketsPath = '/support/tickets';

  static const timeout = Duration(seconds: 30);
}

/// Placeholder until the backend exists: pretends the report was sent so
/// the whole flow can be used and tested end to end.
class PendingSupportApi implements SupportApi {
  const PendingSupportApi();

  @override
  Future<void> submit(SupportTicket ticket) {
    // Lets the payload be checked in `flutter logs` before a backend exists.
    if (kDebugMode) {
      debugPrint(
        'Support ticket (no backend yet, not sent): ${ticket.toFormFields()} '
        '+ ${ticket.screenshotPaths.length} screenshot(s)',
      );
    }
    return Future.delayed(const Duration(milliseconds: 600));
  }
}

/// Real backend client. Sends one multipart/form-data POST to
/// `<baseUrl><ticketsPath>` with:
///
/// - `issue`: [SupportIssue.code] (`wrong_calculation`, `alert_not_shown`, `other`)
/// - `email`: always
/// - `phone_model`: for the first two issues, as typed by the user
/// - `description`: for `other`
/// - `device_time`: always; phone's local time with offset, ISO 8601
/// - `app_version`, `app_build`, `android_version`, `android_sdk`,
///   `device_manufacturer`, `device_brand`, `device_model`: read from
///   Android automatically; omitted only if they couldn't be read
/// - `screenshots`: zero or more image files
///
/// Any 2xx response counts as success. Adjust the field names here if the
/// backend expects different ones.
class HttpSupportApi implements SupportApi {
  HttpSupportApi(this.baseUrl, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUrl;
  final http.Client _client;

  @override
  Future<void> submit(SupportTicket ticket) async {
    final request = http.MultipartRequest(
      'POST',
      baseUrl.resolve(SupportApiConfig.ticketsPath),
    )..fields.addAll(ticket.toFormFields());
    for (final path in ticket.screenshotPaths) {
      request.files.add(await http.MultipartFile.fromPath('screenshots', path));
    }

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(SupportApiConfig.timeout);
    } on Exception catch (e) {
      throw SupportApiException('No se pudo conectar: $e');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw SupportApiException('HTTP ${response.statusCode}: $body');
    }
  }
}
