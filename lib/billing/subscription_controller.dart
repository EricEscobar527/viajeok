import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/app_prefs.dart';
import '../platform/trip_reader.dart';
import 'billing_api.dart';
import 'store.dart';

enum SubscriptionError {
  /// Play couldn't complete the purchase.
  purchaseFailed,

  /// Play charged, but the backend couldn't confirm it yet; Restaurar
  /// compra retries.
  verifyFailed,
}

enum ProductState { loading, ready, unavailable }

/// Decides whether the app is unlocked. The backend's remote config is the
/// switch (`paywall_enabled`); Google Play sells the subscription and the
/// backend verifies it. Both the config and the verified status are cached,
/// so the app behaves the same offline.
class SubscriptionController extends ChangeNotifier {
  SubscriptionController({
    required AppPrefs prefs,
    required this._backend,
    required this._store,
    this.appBuild,
    DateTime Function()? clock,
  }) : _prefs = prefs,
       _clock = clock ?? DateTime.now {
    _config =
        _decode(prefs.remoteConfigJson, RemoteConfig.fromJson) ??
        const RemoteConfig();
    _entitlement =
        _decode(prefs.entitlementJson, Entitlement.fromJson) ??
        Entitlement.none;
  }

  /// Once a subscription's paid period ends, the native service keeps
  /// analysing this long, so a renewal the app hasn't re-verified yet
  /// (phone offline, app not opened) doesn't cut a driver off mid-shift.
  static const lockGrace = Duration(days: 1);

  final AppPrefs _prefs;
  final BillingBackend _backend;
  final Store _store;
  final DateTime Function() _clock;

  /// This build's number (pubspec `+N`); null when unknown (tests, non-
  /// Android), which never forces an update.
  final int? appBuild;

  late RemoteConfig _config;
  late Entitlement _entitlement;
  StoreProduct? _product;
  ProductState _productState = ProductState.loading;
  bool _busy = false;
  SubscriptionError? _error;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  RemoteConfig get config => _config;
  Entitlement get entitlement => _entitlement;
  StoreProduct? get product => _product;
  ProductState get productState => _productState;

  /// A purchase is being processed.
  bool get busy => _busy;

  /// Last purchase problem, for the subscription screen.
  SubscriptionError? get error => _error;

  bool get isSubscribed => _entitlement.isValidAt(_clock());

  /// Analysis is locked: billing is on and there's no valid subscription.
  bool get needsSubscription => _config.paywallEnabled && !isSubscribed;

  /// The backend says this build is too old to keep using.
  bool get updateRequired =>
      appBuild != null && _config.minSupportedBuild > appBuild!;

  /// Free-beta notice text, while billing is off.
  String? get betaMessage =>
      _config.paywallEnabled ? null : _config.betaMessage;

  /// Call once at startup: listens to purchases, refreshes the remote
  /// config and re-verifies the subscription Play has for this account
  /// (picks up renewals, and refunds the backend reports as inactive).
  /// Any failure keeps the cached state.
  Future<void> start() async {
    _purchaseSub ??= _store.purchases.listen(_onPurchases);
    await _pushLock();
    await refreshConfig();
    if (_config.paywallEnabled) await restore();
  }

  Future<void> refreshConfig() async {
    try {
      _config = await _backend.fetchConfig();
      await _prefs.setRemoteConfigJson(jsonEncode(_config.toJson()));
      await _pushLock();
      notifyListeners();
    } on Exception catch (e) {
      debugPrint('Remote config not refreshed, using cached: $e');
    }
  }

  /// Loads the subscription's price for the subscription screen.
  Future<void> loadProduct() async {
    // Only on a retry: the first call runs during the screen's first build.
    if (_productState != ProductState.loading) {
      _productState = ProductState.loading;
      notifyListeners();
    }
    try {
      if (await _store.isAvailable()) {
        _product = await _store.product(_config.productId);
      }
    } on Exception catch (e) {
      debugPrint('Subscription product not loaded: $e');
    }
    _productState = _product == null
        ? ProductState.unavailable
        : ProductState.ready;
    notifyListeners();
  }

  /// Opens Play's purchase sheet; the result arrives on the purchase stream.
  Future<void> buy() async {
    final product = _product;
    if (product == null) return;
    _setBusy(true, error: null);
    try {
      await _store.buy(product);
    } on Exception catch (e) {
      debugPrint('Purchase not started: $e');
      _setBusy(false, error: SubscriptionError.purchaseFailed);
    }
  }

  /// Asks Play for purchases this account already owns; each one is
  /// verified with the backend like a new purchase.
  Future<void> restore() async {
    try {
      if (!await _store.isAvailable()) return;
      await _store.restore();
    } on Exception catch (e) {
      debugPrint('Restore failed: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _setBusy(true);
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          await _verify(p);
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${p.error}');
          _setBusy(false, error: SubscriptionError.purchaseFailed);
        case PurchaseStatus.canceled:
          _setBusy(false, error: null);
      }
      // Completed even when our backend is down: the user did pay, and an
      // unacknowledged purchase is refunded by Play after 3 days.
      if (p.pendingCompletePurchase) {
        await _store.complete(p);
      }
    }
  }

  Future<void> _verify(PurchaseDetails p) async {
    try {
      final result = await _backend.verify(
        productId: p.productID,
        purchaseToken: p.verificationData.serverVerificationData,
        installId: await _prefs.installId(),
      );
      _entitlement = result;
      await _prefs.setEntitlementJson(jsonEncode(result.toJson()));
      await _pushLock();
      _setBusy(false, error: null);
    } on Exception catch (e) {
      debugPrint('Purchase not verified: $e');
      _setBusy(false, error: SubscriptionError.verifyFailed);
    }
  }

  /// When the native service must stop analysing by itself.
  @visibleForTesting
  DateTime? get lockAt {
    if (!_config.paywallEnabled) return null;
    if (!isSubscribed) return _clock();
    return _entitlement.expiresAt?.add(lockGrace);
  }

  Future<void> _pushLock() => TripReader.setLockAt(lockAt);

  void _setBusy(bool value, {Object? error = _keep}) {
    _busy = value;
    if (!identical(error, _keep)) _error = error as SubscriptionError?;
    notifyListeners();
  }

  static const _keep = Object();

  static T? _decode<T>(String? json, T Function(Map<String, Object?>) parse) {
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? parse(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
