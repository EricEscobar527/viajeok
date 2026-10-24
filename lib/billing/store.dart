import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// The subscription as the store offers it.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.price,
    this.trialPeriod,
    required this.raw,
  });

  final String id;

  /// Localized recurring price, e.g. "$99.00".
  final String price;

  /// Free-trial length as Play gives it (ISO 8601, e.g. "P7D", "P1M");
  /// null when there's no trial (e.g. this account already used it).
  final String? trialPeriod;

  /// The plugin's ProductDetails, passed back to [Store.buy].
  final Object raw;
}

/// Google Play billing, behind an interface so the controller can be tested.
abstract interface class Store {
  Stream<List<PurchaseDetails>> get purchases;
  Future<bool> isAvailable();
  Future<StoreProduct?> product(String id);
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

  // Play returns one entry per subscription offer; prefer the one with the
  // free trial so new subscribers get it.
  @override
  Future<StoreProduct?> product(String id) async {
    final response = await _iap.queryProductDetails({id});
    final offers = response.productDetails.where((d) => d.id == id).toList();
    if (offers.isEmpty) return null;
    final chosen =
        offers.where((d) => _trial(d) != null).firstOrNull ?? offers.first;
    return StoreProduct(
      id: chosen.id,
      price: _recurringPrice(chosen) ?? chosen.price,
      trialPeriod: _trial(chosen)?.billingPeriod,
      raw: chosen,
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

  static List<PricingPhaseWrapper> _phases(ProductDetails d) {
    if (d is! GooglePlayProductDetails) return const [];
    final index = d.subscriptionIndex;
    final offers = d.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) {
      return const [];
    }
    return offers[index].pricingPhases;
  }

  static PricingPhaseWrapper? _trial(ProductDetails d) =>
      _phases(d).where((p) => p.priceAmountMicros == 0).firstOrNull;

  /// The paid phase's price, rather than the $0 trial phase.
  static String? _recurringPrice(ProductDetails d) =>
      _phases(d)
          .where((p) => p.priceAmountMicros > 0)
          .lastOrNull
          ?.formattedPrice;
}
