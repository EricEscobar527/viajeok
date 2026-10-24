import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:viajeok/data/app_prefs.dart';
import 'package:viajeok/main.dart';

import 'billing_fakes.dart';

Future<AppPrefs> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AppPrefs.load();
}

/// The app with billing off (the backend can't be reached, no cache).
MyApp _app(AppPrefs prefs) =>
    MyApp(prefs: prefs, subscriptions: freeController(prefs));

void main() {
  testWidgets('first launch shows the single welcome screen', (tester) async {
    final prefs = await _prefs({});
    await tester.pumpWidget(_app(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar análisis'), findsOneWidget);
    expect(prefs.onboardingDone, isTrue);
  });

  testWidgets('later launches go straight to the panel', (tester) async {
    await tester.pumpWidget(_app(await _prefs({'onboarding_done': true})));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar análisis'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Mis mínimos'), 200);
    expect(find.text('Por km'), findsOneWidget);
  });

  testWidgets('turning a minimum on reveals its slider', (tester) async {
    await tester.pumpWidget(_app(await _prefs({'onboarding_done': true})));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Por km'), 200);
    expect(find.byType(Slider), findsNothing);

    final perKmSwitch = find.descendant(
      of: find.ancestor(of: find.text('Por km'), matching: find.byType(Row)),
      matching: find.byType(Switch),
    );
    await tester.tap(perKmSwitch.first);
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('\$8 / km'), findsOneWidget);
  });

  testWidgets('stays in Spanish even on an English phone', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(_app(await _prefs({})));
    await tester.pumpAndSettle();

    expect(find.text('Empezar'), findsOneWidget);
  });

  testWidgets('starting without the service shows the disclosure first', (
    tester,
  ) async {
    await tester.pumpWidget(_app(await _prefs({'onboarding_done': true})));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar análisis'));
    await tester.pumpAndSettle();
    expect(find.text('Antes de activar'), findsOneWidget);
    expect(find.text('Acepto'), findsOneWidget);

    // Declining goes back without opening Android's settings.
    await tester.tap(find.text('No acepto'));
    await tester.pumpAndSettle();
    expect(find.text('Antes de activar'), findsNothing);
    expect(find.text('Iniciar análisis'), findsOneWidget);

    await tester.tap(find.text('Iniciar análisis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acepto'));
    await tester.pumpAndSettle();
    expect(find.text('Antes de activar'), findsNothing);
  });
}
