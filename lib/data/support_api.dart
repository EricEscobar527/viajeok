import 'package:http/http.dart' as http;

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

/// A support report as the form collects it.
class SupportTicket {
  const SupportTicket({
    required this.issue,
    this.phoneModel,
    this.email,
    this.description,
    this.screenshotPaths = const [],
  });

  final SupportIssue issue;
  final String? phoneModel;
  final String? email;
  final String? description;

  /// Local file paths of the screenshots the user picked.
  final List<String> screenshotPaths;
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
  Future<void> submit(SupportTicket ticket) =>
      Future.delayed(const Duration(milliseconds: 600));
}

/// Real backend client. Sends one multipart/form-data POST to
/// `<baseUrl><ticketsPath>` with:
///
/// - `issue`: [SupportIssue.code] (`wrong_calculation`, `alert_not_shown`, `other`)
/// - `email`: always
/// - `phone_model`: for the first two issues
/// - `description`: for `other`
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
    final request =
        http.MultipartRequest(
            'POST',
            baseUrl.resolve(SupportApiConfig.ticketsPath),
          )
          ..fields['issue'] = ticket.issue.code
          ..fields.addAll({
            if (ticket.phoneModel != null) 'phone_model': ticket.phoneModel!,
            if (ticket.email != null) 'email': ticket.email!,
            if (ticket.description != null) 'description': ticket.description!,
          });
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
