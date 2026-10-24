import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:viajeok/billing/billing_api.dart';
import 'package:viajeok/billing/store.dart';
import 'package:viajeok/billing/subscription_controller.dart';
import 'package:viajeok/data/app_prefs.dart';

class FakeBackend implements BillingBackend {
  FakeBackend({this.config, this.entitlement});

  /// Null = the backend can't be reached.
  RemoteConfig? config;
  Entitlement? entitlement;
  final verified = <String>[];

  @override
  Future<RemoteConfig> fetchConfig() async =>
      config ?? (throw const BillingBackendException('offline'));

  @override
  Future<Entitlement> verify({
    required String productId,
    required String purchaseToken,
    required String installId,
  }) async {
    verified.add(purchaseToken);
    return entitlement ?? (throw const BillingBackendException('offline'));
  }
}

class FakeStore implements Store {
  FakeStore({this.available = true, this.offered});

  bool available;
  StoreProduct? offered;
  final owned = <PurchaseDetails>[];
  final completed = <PurchaseDetails>[];
  final _purchases = StreamController<List<PurchaseDetails>>.broadcast();

  static const monthly = StoreProduct(
    id: RemoteConfig.defaultProductId,
    price: r'$99.00',
    trialPeriod: 'P7D',
    raw: Object(),
  );

  static PurchaseDetails purchase(String token, PurchaseStatus status) =>
      PurchaseDetails(
        productID: RemoteConfig.defaultProductId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: token,
          source: 'google_play',
        ),
        transactionDate: null,
        status: status,
      )..pendingCompletePurchase = true;

  void emit(List<PurchaseDetails> purchases) => _purchases.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchases => _purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<StoreProduct?> product(String id) async => offered;

  @override
  Future<void> buy(StoreProduct product) async =>
      emit([purchase('new-token', PurchaseStatus.purchased)]);

  @override
  Future<void> restore() async => emit(owned);

  @override
  Future<void> complete(PurchaseDetails purchase) async =>
      completed.add(purchase);
}

SubscriptionController freeController(AppPrefs prefs) => SubscriptionController(
  prefs: prefs,
  backend: FakeBackend(),
  store: FakeStore(),
);
