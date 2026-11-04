import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:viajeok/billing/billing_api.dart';
import 'package:viajeok/billing/subscription_controller.dart';
import 'package:viajeok/billing/subscription_screen.dart';
import 'package:viajeok/data/app_prefs.dart';
import 'package:viajeok/l10n/app_localizations_es.dart';
import 'package:viajeok/main.dart';

import 'billing_fakes.dart';

final now = DateTime.utc(2026, 12, 2, 15);
const paid = RemoteConfig(paywallEnabled: true);
final active = Entitlement(
  active: true,
  inTrial: true,
  expiresAt: now.add(const Duration(days: 7)),
);

Future<AppPrefs> _prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return AppPrefs.load();
}

SubscriptionController _controller(
  AppPrefs prefs, {
  FakeBackend? backend,
  FakeStore? store,
  int? appBuild,
}) => SubscriptionController(
  prefs: prefs,
  backend: backend ?? FakeBackend(),
  store: store ?? FakeStore(),
  appBuild: appBuild,
  clock: () => now,
);

/// Lets purchase-stream events and the futures they start run.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('SubscriptionController', () {
    test('is free until the backend turns billing on', () async {
      final subs = _controller(await _prefs());
      await subs.start();
      expect(subs.needsSubscription, isFalse);
      expect(subs.lockAt, isNull);
    });

    test('locks without a subscription once billing is on', () async {
      final subs = _controller(
        await _prefs(),
        backend: FakeBackend(config: paid),
      );
      await subs.start();
      expect(subs.needsSubscription, isTrue);
      expect(subs.lockAt, now);
    });

    test('recovers an owned subscription on start', () async {
      final prefs = await _prefs();
      final store = FakeStore()
        ..owned.add(FakeStore.purchase('tok', PurchaseStatus.restored));
      final backend = FakeBackend(config: paid, entitlement: active);
      final subs = _controller(prefs, backend: backend, store: store);

      await subs.start();
      await _settle();

      expect(backend.verified, ['tok']);
      expect(store.completed, hasLength(1));
      expect(subs.needsSubscription, isFalse);
      expect(subs.lockAt, active.expiresAt!.add(const Duration(days: 1)));
      // Cached for the next launch, which may be offline.
      final offline = _controller(prefs);
      await offline.start();
      expect(offline.needsSubscription, isFalse);
    });

    test('offline keeps the cached switch', () async {
      final prefs = await _prefs({'remote_config': jsonEncode(paid.toJson())});
      final subs = _controller(prefs);
      await subs.start();
      expect(subs.config.paywallEnabled, isTrue);
      expect(subs.needsSubscription, isTrue);
    });

    test('an expired subscription locks again', () async {
      final expired = Entitlement(
        active: true,
        expiresAt: now.subtract(const Duration(minutes: 1)),
      );
      final subs = _controller(
        await _prefs({'entitlement': jsonEncode(expired.toJson())}),
        backend: FakeBackend(config: paid),
      );
      await subs.start();
      expect(subs.needsSubscription, isTrue);
    });

    test('a purchase the backend cannot verify is still completed', () async {
      final store = FakeStore(offered: FakeStore.monthly);
      final subs = _controller(
        await _prefs(),
        backend: FakeBackend(config: paid),
        store: store,
      );
      await subs.start();
      await subs.loadProduct();
      await subs.buy();
      await _settle();

      expect(subs.error, SubscriptionError.verifyFailed);
      expect(subs.needsSubscription, isTrue);
      expect(store.completed, hasLength(1));
    });

    test('asks old builds to update', () async {
      final subs = _controller(
        await _prefs(),
        backend: FakeBackend(config: const RemoteConfig(minSupportedBuild: 5)),
        appBuild: 4,
      );
      await subs.start();
      expect(subs.updateRequired, isTrue);
    });
  });

  group('plans', () {
    test(
      'monthly with trial starts selected; any plan can be bought',
      () async {
        final store = FakeStore(
          plans: const [
            FakeStore.monthlyPlan,
            FakeStore.quarterlyPlan,
            FakeStore.yearlyPlan,
          ],
        );
        final subs = _controller(
          await _prefs(),
          backend: FakeBackend(config: paid, entitlement: active),
          store: store,
        );
        await subs.start();
        await subs.loadProduct();
        expect(subs.plans, hasLength(3));
        expect(subs.product, same(FakeStore.monthlyPlan));

        subs.select(FakeStore.yearlyPlan);
        await subs.buy();
        await _settle();
        expect(store.bought.single, same(FakeStore.yearlyPlan));
        expect(subs.isSubscribed, isTrue);
      },
    );

    test('names, prices and savings', () {
      final t = AppLocalizationsEs();
      const m = FakeStore.monthlyPlan;
      const q = FakeStore.quarterlyPlan;
      const y = FakeStore.yearlyPlan;
      expect(
        [planName(t, m), planName(t, q), planName(t, y)],
        ['Mensual', 'Trimestral', 'Anual'],
      );
      expect(planPrice(t, m), r'$89.00 al mes');
      expect(planPrice(t, q), r'$200.00 cada 3 meses');
      expect(planPrice(t, y), r'$500.00 al año');
      // $200 vs 3 × $89 = $267 → 25%; $500 vs 12 × $89 = $1,068 → 53%.
      expect(savingsPercent(m, m), isNull);
      expect(savingsPercent(q, m), 25);
      expect(savingsPercent(y, m), 53);
      expect(savingsPercent(y, null), isNull);
    });
  });

  group('free until', () {
    SubscriptionController at(
      AppPrefs prefs,
      DateTime clock, {
      RemoteConfig? config,
    }) => SubscriptionController(
      prefs: prefs,
      backend: FakeBackend(config: config),
      store: FakeStore(),
      clock: () => clock,
    );

    test(
      'December 7 while free, whatever the date: only billing hides it',
      () async {
        final prefs = await _prefs();
        expect(at(prefs, now).freeUntil, DateTime(2026, 12, 7));
        expect(
          at(prefs, DateTime(2026, 12, 20)).freeUntil,
          DateTime(2026, 12, 7),
        );
      },
    );

    test('hidden once billing is on; the backend can move the date', () async {
      final paidSubs = at(await _prefs(), now, config: paid);
      await paidSubs.start();
      expect(paidSubs.freeUntil, isNull);

      final later = at(
        await _prefs(),
        now,
        config: RemoteConfig(betaEndsAt: DateTime(2026, 12, 12)),
      );
      await later.start();
      expect(later.freeUntil, DateTime(2026, 12, 12));
    });
  });

  test('the backend sends the free date without time or zone', () async {
    // GET /app/config since Nov 4, 2026: "beta_ends_at": "2026-12-07" (or null).
    for (final (json, day) in [
      ({'beta_ends_at': '2026-12-07'}, DateTime(2026, 12, 7)),
      ({'beta_ends_at': null}, DateTime(2026, 12, 7)),
    ]) {
      final subs = _controller(
        await _prefs(),
        backend: FakeBackend(config: RemoteConfig.fromJson(json)),
      );
      await subs.start();
      expect(subs.freeUntil, day);
    }
  });

  test('reads Play trial periods', () {
    final t = AppLocalizationsEs();
    expect(trialLabel(t, 'P7D'), '7 días gratis');
    expect(trialLabel(t, 'P1W'), '1 semana gratis');
    expect(trialLabel(t, 'P1M'), '1 mes gratis');
    expect(trialLabel(t, null), isNull);
  });

  group('app', () {
    Future<SubscriptionController> started(SubscriptionController subs) async {
      await subs.start();
      return subs;
    }

    testWidgets('Iniciar asks for the subscription first', (tester) async {
      final prefs = await _prefs({'onboarding_done': true});
      final subs = await started(
        _controller(
          prefs,
          backend: FakeBackend(config: paid, entitlement: active),
          store: FakeStore(offered: FakeStore.monthly),
        ),
      );
      await tester.pumpWidget(MyApp(prefs: prefs, subscriptions: subs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar análisis'));
      await tester.pumpAndSettle();
      expect(find.text('7 días gratis'), findsOneWidget);
      expect(find.text(r'Después, $99.00 al mes'), findsOneWidget);

      await tester.tap(find.text('Empezar prueba gratis'));
      await tester.pumpAndSettle();

      // Subscribed: back on the panel, which continues to the disclosure.
      expect(find.text('Empezar prueba gratis'), findsNothing);
      expect(find.text('Antes de activar'), findsOneWidget);
    });

    testWidgets('shows the three plans and buys the one picked', (
      tester,
    ) async {
      final prefs = await _prefs({'onboarding_done': true});
      final store = FakeStore(
        plans: const [
          FakeStore.monthlyPlan,
          FakeStore.quarterlyPlan,
          FakeStore.yearlyPlan,
        ],
      );
      final subs = await started(
        _controller(
          prefs,
          backend: FakeBackend(config: paid, entitlement: active),
          store: store,
        ),
      );
      await tester.pumpWidget(MyApp(prefs: prefs, subscriptions: subs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar análisis'));
      await tester.pumpAndSettle();
      expect(find.text('1 mes gratis'), findsOneWidget);
      expect(find.text(r'Después, $89.00 al mes'), findsOneWidget);
      expect(find.text(r'$200.00 cada 3 meses'), findsOneWidget);
      expect(find.text('Ahorras 25%'), findsOneWidget);
      expect(find.text(r'$500.00 al año'), findsOneWidget);
      expect(find.text('Ahorras 53%'), findsOneWidget);

      await tester.ensureVisible(find.text(r'$500.00 al año'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'$500.00 al año'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Suscribirme'), 100);
      await tester.tap(find.text('Suscribirme'));
      await tester.pumpAndSettle();
      expect(store.bought.single, same(FakeStore.yearlyPlan));
    });

    const freeNote =
        'ViajeOK es gratis hasta el 7 de diciembre de 2026. Después, la '
        r'suscripción costará $90 al mes, $200 cada 3 meses o $500 al año.';

    Future<void> openSupport(WidgetTester tester, RemoteConfig? config) async {
      final prefs = await _prefs({'onboarding_done': true});
      final subs = await started(
        _controller(
          prefs,
          backend: FakeBackend(config: config, entitlement: active),
        ),
      );
      await tester.pumpWidget(MyApp(prefs: prefs, subscriptions: subs));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Soporte'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Política de privacidad'), 200);
    }

    testWidgets('Soporte says until when it is free and the fixed prices', (
      tester,
    ) async {
      await openSupport(tester, null);
      expect(find.text(freeNote), findsOneWidget);
    });

    testWidgets('the note goes away once the backend turns billing on', (
      tester,
    ) async {
      await openSupport(tester, paid);
      expect(find.text(freeNote), findsNothing);
    });

    testWidgets('shows the beta notice while billing is off', (tester) async {
      final prefs = await _prefs({'onboarding_done': true});
      final subs = await started(
        _controller(
          prefs,
          backend: FakeBackend(
            config: const RemoteConfig(betaMessage: 'Gratis hasta el 1 de dic'),
          ),
        ),
      );
      await tester.pumpWidget(MyApp(prefs: prefs, subscriptions: subs));
      await tester.pumpAndSettle();

      expect(find.text('Gratis hasta el 1 de dic'), findsOneWidget);
      await tester.tap(find.text('Iniciar análisis'));
      await tester.pumpAndSettle();
      expect(find.text('Antes de activar'), findsOneWidget);
    });

    testWidgets('blocks old builds', (tester) async {
      final prefs = await _prefs({'onboarding_done': true});
      final subs = await started(
        _controller(
          prefs,
          backend: FakeBackend(
            config: const RemoteConfig(minSupportedBuild: 9),
          ),
          appBuild: 3,
        ),
      );
      await tester.pumpWidget(MyApp(prefs: prefs, subscriptions: subs));
      await tester.pumpAndSettle();

      expect(find.text('Actualiza ViajeOK'), findsOneWidget);
      expect(find.text('Iniciar análisis'), findsNothing);
    });
  });
}
