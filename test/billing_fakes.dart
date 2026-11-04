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
  FakeStore({
    this.available = true,
    StoreProduct? offered,
    List<StoreProduct>? plans,
  }) : offered = plans ?? [?offered];

  bool available;
  List<StoreProduct> offered;
  final bought = <StoreProduct>[];
  final owned = <PurchaseDetails>[];
  final completed = <PurchaseDetails>[];
  final _purchases = StreamController<List<PurchaseDetails>>.broadcast();

  static const monthly = StoreProduct(
    id: RemoteConfig.defaultProductId,
    price: r'$99.00',
    trialPeriod: 'P7D',
    raw: Object(),
  );

  // The three plans as set up in Play Console: 1-month trial + $89/month,
  // $200 every 3 months, $500 a year.
  static const monthlyPlan = StoreProduct(
    id: RemoteConfig.defaultProductId,
    price: r'$89.00',
    trialPeriod: 'P1M',
    priceMicros: 89000000,
    raw: Object(),
  );
  static const quarterlyPlan = StoreProduct(
    id: RemoteConfig.defaultProductId,
    price: r'$200.00',
    billingPeriod: 'P3M',
    priceMicros: 200000000,
    raw: Object(),
  );
  static const yearlyPlan = StoreProduct(
    id: RemoteConfig.defaultProductId,
    price: r'$500.00',
    billingPeriod: 'P1Y',
    priceMicros: 500000000,
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
  Future<List<StoreProduct>> plans(String id) async => offered;

  @override
  Future<void> buy(StoreProduct product) async {
    bought.add(product);
    emit([purchase('new-token', PurchaseStatus.purchased)]);
  }

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
