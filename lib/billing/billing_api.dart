import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/support_api.dart' show SupportApiConfig;

/// What the backend's `GET /app/config` says about billing. Defaults are
/// what the app does before it has ever reached the backend: free.
class RemoteConfig {
  const RemoteConfig({
    this.paywallEnabled = false,
    this.betaEndsAt,
    this.betaMessage,
    this.productId = defaultProductId,
    this.minSupportedBuild = 0,
  });

  static const defaultProductId = 'viajeok_mensual';

  /// The switch: when true, analysis needs an active subscription.
  final bool paywallEnabled;

  /// Shown in the beta notice only; it doesn't turn billing on by itself.
  final DateTime? betaEndsAt;
  final String? betaMessage;

  /// Subscription product id in Play Console.
  final String productId;

  /// Builds below this (the `+N` in pubspec `version`) must update.
  final int minSupportedBuild;

  factory RemoteConfig.fromJson(Map<String, Object?> j) => RemoteConfig(
    paywallEnabled: j['paywall_enabled'] == true,
    betaEndsAt: DateTime.tryParse(j['beta_ends_at'] as String? ?? ''),
    betaMessage: (j['beta_message'] as String?)?.trim().isEmpty ?? true
        ? null
        : (j['beta_message'] as String).trim(),
    productId: (j['subscription_product_id'] as String?)?.isNotEmpty == true
        ? j['subscription_product_id'] as String
        : defaultProductId,
    minSupportedBuild: (j['min_supported_build'] as num?)?.toInt() ?? 0,
  );

  Map<String, Object?> toJson() => {
    'paywall_enabled': paywallEnabled,
    'beta_ends_at': betaEndsAt?.toIso8601String(),
    'beta_message': betaMessage,
    'subscription_product_id': productId,
    'min_supported_build': minSupportedBuild,
  };
}

/// Subscription status as the backend verified it with Google Play.
class Entitlement {
  const Entitlement({
    this.active = false,
    this.inTrial = false,
    this.expiresAt,
  });

  static const none = Entitlement();

  final bool active;
  final bool inTrial;
  final DateTime? expiresAt;

  /// Active and not past its expiry (checked against the phone clock; the
  /// backend re-verifies on expiry, so a wrong clock only delays that).
  bool isValidAt(DateTime now) =>
      active && (expiresAt == null || expiresAt!.isAfter(now));

  factory Entitlement.fromJson(Map<String, Object?> j) => Entitlement(
    active: j['active'] == true,
    inTrial: j['in_trial'] == true,
    expiresAt: DateTime.tryParse(j['expires_at'] as String? ?? ''),
  );

  Map<String, Object?> toJson() => {
    'active': active,
    'in_trial': inTrial,
    'expires_at': expiresAt?.toUtc().toIso8601String(),
  };
}

/// The two billing endpoints of the backend (same base URL and bearer token
/// as support; see [SupportApiConfig]).
abstract interface class BillingBackend {
  /// `GET <base>/app/config`.
  Future<RemoteConfig> fetchConfig();

  /// `POST <base>/subscriptions/verify` with a Google Play purchase token.
  Future<Entitlement> verify({
    required String productId,
    required String purchaseToken,
    required String installId,
  });

  factory BillingBackend.create() => SupportApiConfig.isConfigured
      ? HttpBillingBackend(
          Uri.parse(SupportApiConfig.baseUrl),
          token: SupportApiConfig.token,
        )
      : const UnconfiguredBillingBackend();
}

class BillingBackendException implements Exception {
  const BillingBackendException(this.message);

  final String message;

  @override
  String toString() => 'BillingBackendException: $message';
}

/// Built without the API config: nothing can be fetched or verified.
class UnconfiguredBillingBackend implements BillingBackend {
  const UnconfiguredBillingBackend();

  @override
  Future<RemoteConfig> fetchConfig() =>
      throw const BillingBackendException('Billing API not configured');

  @override
  Future<Entitlement> verify({
    required String productId,
    required String purchaseToken,
    required String installId,
  }) => throw const BillingBackendException('Billing API not configured');
}

class HttpBillingBackend implements BillingBackend {
  HttpBillingBackend(Uri baseUrl, {required this.token, http.Client? client})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl.path.endsWith('/')
          ? baseUrl
          : baseUrl.replace(path: '${baseUrl.path}/');

  static const packageName = 'cloud.doublee.viajeok';
  static const timeout = Duration(seconds: 20);

  final Uri baseUrl;
  final String token;
  final http.Client _client;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  @override
  Future<RemoteConfig> fetchConfig() async {
    final res = await _send(
      () => _client.get(baseUrl.resolve('app/config'), headers: _headers),
    );
    return RemoteConfig.fromJson(_json(res));
  }

  @override
  Future<Entitlement> verify({
    required String productId,
    required String purchaseToken,
    required String installId,
  }) async {
    final res = await _send(
      () => _client.post(
        baseUrl.resolve('subscriptions/verify'),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'package_name': packageName,
          'product_id': productId,
          'purchase_token': purchaseToken,
          'install_id': installId,
        }),
      ),
    );
    return Entitlement.fromJson(_json(res));
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call().timeout(timeout);
    } on Exception catch (e) {
      throw BillingBackendException('$e');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BillingBackendException('HTTP ${res.statusCode}: ${res.body}');
    }
    return res;
  }

  static Map<String, Object?> _json(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Fall through.
    }
    throw BillingBackendException('Unexpected body: ${res.body}');
  }
}
