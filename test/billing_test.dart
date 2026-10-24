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
