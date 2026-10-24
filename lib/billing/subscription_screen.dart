import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../platform/trip_reader.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'billing_api.dart';
import 'subscription_controller.dart';

/// Play's subscription management page for this app.
Future<void> openManageSubscription(String productId) => TripReader.openUrl(
  'https://play.google.com/store/account/subscriptions'
  '?sku=$productId&package=${HttpBillingBackend.packageName}',
);

/// Paywall shown when analysis is started without an active subscription.
/// Pops true once the subscription is verified.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, required this.subscriptions});

  final SubscriptionController subscriptions;

  static Future<bool> show(
    BuildContext context,
    SubscriptionController subscriptions,
  ) async =>
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SubscriptionScreen(subscriptions: subscriptions),
        ),
      ) ??
      false;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionController get _subs => widget.subscriptions;

  @override
  void initState() {
    super.initState();
    _subs.addListener(_closeWhenSubscribed);
    _subs.loadProduct();
  }

  @override
  void dispose() {
    _subs.removeListener(_closeWhenSubscribed);
    super.dispose();
  }

  void _closeWhenSubscribed() {
    if (_subs.isSubscribed && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _subs,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                t.subTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.subSubtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FeatureRow(
                icon: Icons.notifications_active_outlined,
                title: t.subFeatureAnalysis,
                subtitle: t.subFeatureAnalysisText,
              ),
              FeatureRow(
                icon: Icons.tune_outlined,
                title: t.subFeatureFilters,
                subtitle: t.subFeatureFiltersText,
              ),
              FeatureRow(
                icon: Icons.event_available_outlined,
                title: t.subFeatureCancel,
                subtitle: t.subFeatureCancelText,
              ),
              const SizedBox(height: 20),
              ..._offer(t),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _subs.busy ? null : _subs.restore,
                  child: Text(t.btnRestorePurchase),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _offer(AppLocalizations t) {
    switch (_subs.productState) {
      case ProductState.loading:
        return const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case ProductState.unavailable:
        return [
          Text(
            t.subUnavailable,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: t.btnRetry, onPressed: _subs.loadProduct),
        ];
      case ProductState.ready:
        final product = _subs.product!;
        final trial = trialLabel(t, product.trialPeriod);
        final error = switch (_subs.error) {
          SubscriptionError.purchaseFailed => t.subErrorPurchase,
          SubscriptionError.verifyFailed => t.subErrorVerify,
          null => null,
        };
        return [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trial ?? t.subPricePerMonth(product.price),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (trial != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    t.subTrialThen(product.price),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (error != null) ...[
            Text(error, style: const TextStyle(color: AppColors.red)),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            label: trial != null ? t.btnStartTrial : t.btnSubscribe,
            onPressed: _subs.busy ? null : _subs.buy,
          ),
          const SizedBox(height: 12),
          Text(
            t.subRenewalNote,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ];
    }
  }
}

/// "7 días gratis" from Play's ISO 8601 period ("P7D", "P1W", "P1M");
/// null without a trial or for a period it can't read.
String? trialLabel(AppLocalizations t, String? period) {
  final m = RegExp(r'^P(\d+)([DWMY])$').firstMatch(period ?? '');
  if (m == null) return null;
  final n = int.parse(m[1]!);
  return switch (m[2]) {
    'D' => t.subTrialDays(n),
    'W' => t.subTrialWeeks(n),
    'M' => t.subTrialMonths(n),
    _ => t.subTrialMonths(n * 12),
  };
}
