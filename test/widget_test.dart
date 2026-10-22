import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:analisis_viaje/data/app_prefs.dart';
import 'package:analisis_viaje/main.dart';

Future<AppPrefs> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AppPrefs.load();
}

void main() {
  testWidgets('first launch shows the single welcome screen', (tester) async {
    final prefs = await _prefs({});
    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar análisis'), findsOneWidget);
    expect(prefs.onboardingDone, isTrue);
  });

  testWidgets('later launches go straight to the panel', (tester) async {
    await tester.pumpWidget(
      MyApp(prefs: await _prefs({'onboarding_done': true})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Iniciar análisis'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Mis mínimos'), 200);
    expect(find.text('Por km'), findsOneWidget);
  });

  testWidgets('turning a minimum on reveals its slider', (tester) async {
    await tester.pumpWidget(
      MyApp(prefs: await _prefs({'onboarding_done': true})),
    );
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

    await tester.pumpWidget(MyApp(prefs: await _prefs({})));
    await tester.pumpAndSettle();

    expect(find.text('Empezar'), findsOneWidget);
  });
}
