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
  testWidgets('first launch shows onboarding after the splash', (tester) async {
    await tester.pumpWidget(MyApp(prefs: await _prefs({})));
    await tester.pumpAndSettle();

    expect(find.text('Configurar ahora'), findsOneWidget);
  });

  testWidgets('later launches go straight to the panel', (tester) async {
    await tester.pumpWidget(
      MyApp(prefs: await _prefs({'onboarding_done': true})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Listo para iniciar'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Filtros inteligentes'), 200);
    expect(find.text('Filtros inteligentes'), findsOneWidget);
  });

  testWidgets('stays in Spanish even on an English phone', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(MyApp(prefs: await _prefs({})));
    await tester.pumpAndSettle();

    expect(find.text('Configurar ahora'), findsOneWidget);
  });
}
