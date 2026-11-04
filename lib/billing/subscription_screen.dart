import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../platform/trip_reader.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'billing_api.dart';
import 'store.dart';
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
        final monthly = _subs.plans.where((p) => p.months == 1).firstOrNull;
        return [
          for (final plan in _subs.plans) ...[
            _PlanCard(
              plan: plan,
              monthly: monthly,
              selected: identical(plan, product),
              onTap: () => _subs.select(plan),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
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

/// One selectable plan: its name, price per period, and the free trial or
/// what it saves against paying monthly.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.monthly,
    required this.selected,
    required this.onTap,
  });

  final StoreProduct plan;

  /// The monthly plan, to work out savings; null if Play has none.
  final StoreProduct? monthly;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final trial = trialLabel(t, plan.trialPeriod);
    final price = planPrice(t, plan);
    final save = savingsPercent(plan, monthly);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName(t, plan),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trial ?? price,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (trial != null)
                      Text(
                        t.subTrialThen(price),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              if (save != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.subSave(save),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Mensual", "Trimestral", "Anual", or "6 meses".
String planName(AppLocalizations t, StoreProduct plan) => switch (plan.months) {
  1 || null => t.subPlanMonthly,
  3 => t.subPlanQuarterly,
  12 => t.subPlanYearly,
  final n => t.subPlanMonths(n),
};

/// "$89.00 al mes", "$200.00 cada 3 meses", "$500.00 al año".
String planPrice(AppLocalizations t, StoreProduct plan) =>
    switch (plan.months) {
      1 || null => t.subPricePerMonth(plan.price),
      12 => t.subPricePerYear(plan.price),
      final n => t.subPriceEveryMonths(plan.price, n),
    };

/// How much [plan] saves against paying [monthly] for as long, in whole
/// percent; null for the monthly plan itself, unknown prices, or under 5%.
int? savingsPercent(StoreProduct plan, StoreProduct? monthly) {
  final months = plan.months;
  if (monthly == null || months == null || months <= 1) return null;
  if (plan.priceMicros <= 0 || monthly.priceMicros <= 0) return null;
  final full = monthly.priceMicros * months;
  final save = ((1 - plan.priceMicros / full) * 100).floor();
  return save >= 5 ? save : null;
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
