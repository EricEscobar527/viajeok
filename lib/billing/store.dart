import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// One plan of the subscription as the store offers it: a Play base plan
/// (monthly, every 3 months, yearly) of the same subscription product.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.price,
    this.trialPeriod,
    this.billingPeriod = 'P1M',
    this.priceMicros = 0,
    required this.raw,
  });

  final String id;

  /// Localized recurring price, e.g. "$99.00".
  final String price;

  /// Free-trial length as Play gives it (ISO 8601, e.g. "P7D", "P1M");
  /// null when there's no trial (e.g. this account already used it).
  final String? trialPeriod;

  /// How often [price] is charged (ISO 8601: "P1M", "P3M", "P1Y").
  final String billingPeriod;

  /// [price] in millionths, to compare plans (0 = unknown).
  final int priceMicros;

  /// The plugin's ProductDetails, passed back to [Store.buy].
  final Object raw;

  /// [billingPeriod] in months; null for one it can't read.
  int? get months {
    final m = RegExp(r'^P(\d+)([MY])$').firstMatch(billingPeriod);
    if (m == null) return null;
    final n = int.parse(m[1]!);
    return m[2] == 'Y' ? n * 12 : n;
  }
}

/// Google Play billing, behind an interface so the controller can be tested.
abstract interface class Store {
  Stream<List<PurchaseDetails>> get purchases;
  Future<bool> isAvailable();

  /// The subscription's plans, shortest period first; empty if none.
  Future<List<StoreProduct>> plans(String id);
  Future<void> buy(StoreProduct product);
  Future<void> restore();
  Future<void> complete(PurchaseDetails purchase);
}

class GooglePlayStore implements Store {
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchases => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  // Play returns one entry per offer of each base plan. One plan per base
  // plan, preferring its free-trial offer so new subscribers get it.
  @override
  Future<List<StoreProduct>> plans(String id) async {
    final response = await _iap.queryProductDetails({id});
    final offers = response.productDetails.where((d) => d.id == id);
    final byBasePlan = <String, List<ProductDetails>>{};
    for (final d in offers) {
      byBasePlan.putIfAbsent(_offer(d)?.basePlanId ?? '', () => []).add(d);
    }
    final plans = [
      for (final group in byBasePlan.values)
        _plan(group.where((d) => _trial(d) != null).firstOrNull ?? group.first),
    ];
    return plans..sort((a, b) => (a.months ?? 99).compareTo(b.months ?? 99));
  }

  static StoreProduct _plan(ProductDetails d) {
    final recurring = _recurring(d);
    return StoreProduct(
      id: d.id,
      price: recurring?.formattedPrice ?? d.price,
      trialPeriod: _trial(d)?.billingPeriod,
      billingPeriod: recurring?.billingPeriod ?? 'P1M',
      priceMicros: recurring?.priceAmountMicros ?? 0,
      raw: d,
    );
  }

  @override
  Future<void> buy(StoreProduct product) => _iap.buyNonConsumable(
    purchaseParam: PurchaseParam(productDetails: product.raw as ProductDetails),
  );

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  static SubscriptionOfferDetailsWrapper? _offer(ProductDetails d) {
    if (d is! GooglePlayProductDetails) return null;
    final index = d.subscriptionIndex;
    final offers = d.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return null;
    return offers[index];
  }

  static List<PricingPhaseWrapper> _phases(ProductDetails d) =>
      _offer(d)?.pricingPhases ?? const [];

  static PricingPhaseWrapper? _trial(ProductDetails d) =>
      _phases(d).where((p) => p.priceAmountMicros == 0).firstOrNull;

  /// The paid phase, rather than the $0 trial phase.
  static PricingPhaseWrapper? _recurring(ProductDetails d) =>
      _phases(d).where((p) => p.priceAmountMicros > 0).lastOrNull;
}
