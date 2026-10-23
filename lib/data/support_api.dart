import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
  /// reproduce; "other" is a free-text message. All of them ask for an
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
    this.message,
    this.screenshotPaths = const [],
    this.device,
  });

  final SupportIssue issue;

  /// The phone's local date/time when the report was sent.
  final DateTime sentAt;

  /// As typed by the user.
  final String? phoneModel;
  final String? email;
  final String? message;

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
    'message': ?message,
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

/// What the backend answered for a created ticket.
class SupportReceipt {
  const SupportReceipt({this.id, this.folio});

  final String? id;

  /// Human-facing ticket number, e.g. "SOP-000003". Null when there's no
  /// backend yet.
  final String? folio;
}

enum SupportFailure {
  /// 429: too many reports from this user/device.
  rateLimited,

  /// 400: a field was missing or invalid, or an image was rejected.
  invalid,

  /// No connection, timeout, 401 (bad token/app disabled) or a server error.
  unavailable,
}

class SupportApiException implements Exception {
  const SupportApiException(this.failure, this.message);

  final SupportFailure failure;
  final String message;

  @override
  String toString() => 'SupportApiException(${failure.name}): $message';
}

/// Sends support reports. The form only depends on this interface.
abstract interface class SupportApi {
  Future<SupportReceipt> submit(SupportTicket ticket);

  /// The real backend when [SupportApiConfig.baseUrl] is configured;
  /// otherwise every send fails, so a build made without the config
  /// can't pretend reports went through.
  factory SupportApi.create() => SupportApiConfig.isConfigured
      ? HttpSupportApi(
          Uri.parse(SupportApiConfig.baseUrl),
          token: SupportApiConfig.token,
        )
      : const UnconfiguredSupportApi();
}

/// Backend settings, injected at build time so the token and URL stay out
/// of the source code and of git:
///
///   flutter run --dart-define-from-file=env/dev.json
///
/// `env/dev.json` (git-ignored; copy `env/example.json`) holds
/// `SUPPORT_API_BASE_URL` and `SUPPORT_API_TOKEN`. Note that anything
/// shipped inside an APK can be extracted: the token identifies the app,
/// it isn't a real secret; the backend's rate limit is the protection.
abstract final class SupportApiConfig {
  /// e.g. 'http://192.168.1.10:8010/api' (phone on the same Wi-Fi as the
  /// dev PC) or the production https URL.
  static const baseUrl = String.fromEnvironment('SUPPORT_API_BASE_URL');
  static const token = String.fromEnvironment('SUPPORT_API_TOKEN');

  static bool get isConfigured => baseUrl.isNotEmpty;

  /// Path of the endpoint that receives reports.
  static const ticketsPath = 'support/tickets';

  static const timeout = Duration(seconds: 30);
}

/// Used when the app was built without `--dart-define-from-file`: reports
/// can't go anywhere, so sending fails (and says why in debug logs).
class UnconfiguredSupportApi implements SupportApi {
  const UnconfiguredSupportApi();

  @override
  Future<SupportReceipt> submit(SupportTicket ticket) async {
    if (kDebugMode) {
      debugPrint(
        'Support ticket NOT sent: no SUPPORT_API_BASE_URL. Build or run with '
        '--dart-define-from-file=env/dev.json. Payload: ${ticket.toFormFields()}',
      );
    }
    throw const SupportApiException(
      SupportFailure.unavailable,
      'Support API not configured',
    );
  }
}

/// Real backend client: one multipart/form-data POST to
/// `<baseUrl>/support/tickets` with `Authorization: Bearer <token>` and:
///
/// - `issue`: [SupportIssue.code] (`wrong_calculation`, `alert_not_shown`, `other`)
/// - `email`: always
/// - `phone_model`: for the first two issues, as typed by the user
/// - `message`: for `other`
/// - `device_time`: always; phone's local time with offset, ISO 8601
/// - `app_version`, `app_build`, `android_version`, `android_sdk`,
///   `device_manufacturer`, `device_brand`, `device_model`: read from
///   Android automatically; omitted only if they couldn't be read
/// - `images`: 0–5 image files, the field repeated once per image
///
/// 201 → `{"id": "...", "folio": "SOP-000003"}`. 400 field errors, 401 bad
/// token/app disabled, 429 rate limited.
class HttpSupportApi implements SupportApi {
  HttpSupportApi(Uri baseUrl, {required this.token, http.Client? client})
    : _client = client ?? http.Client(),
      // Trailing slash so the relative path is appended, not swapped in.
      baseUrl = baseUrl.path.endsWith('/')
          ? baseUrl
          : baseUrl.replace(path: '${baseUrl.path}/');

  final Uri baseUrl;
  final String token;
  final http.Client _client;

  /// Formats the backend accepts, by file extension.
  static const imageTypes = {
    'jpg': 'jpeg',
    'jpeg': 'jpeg',
    'png': 'png',
    'webp': 'webp',
    'gif': 'gif',
  };

  @override
  Future<SupportReceipt> submit(SupportTicket ticket) async {
    final request =
        http.MultipartRequest(
            'POST',
            baseUrl.resolve(SupportApiConfig.ticketsPath),
          )
          // Content-Type with the multipart boundary is set by the request.
          ..headers['Authorization'] = 'Bearer $token'
          ..headers['Accept'] = 'application/json'
          ..fields.addAll(ticket.toFormFields());
    for (final path in ticket.screenshotPaths) {
      final ext = path.split('.').last.toLowerCase();
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          path,
          contentType: MediaType('image', imageTypes[ext] ?? 'jpeg'),
        ),
      );
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(SupportApiConfig.timeout),
      );
    } on Exception catch (e) {
      throw SupportApiException(SupportFailure.unavailable, '$e');
    }

    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      final body = _json(response.body);
      return SupportReceipt(
        id: body['id'] as String?,
        folio: body['folio'] as String?,
      );
    }
    throw SupportApiException(switch (code) {
      429 => SupportFailure.rateLimited,
      400 => SupportFailure.invalid,
      _ => SupportFailure.unavailable,
    }, 'HTTP $code: ${response.body}');
  }

  static Map<String, Object?> _json(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
