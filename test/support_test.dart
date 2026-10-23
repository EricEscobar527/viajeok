import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:viajeok/data/support_api.dart';
import 'package:viajeok/l10n/app_localizations.dart';
import 'package:viajeok/support/support_screen.dart';

class _FakeApi implements SupportApi {
  _FakeApi({this.failure});

  final SupportFailure? failure;
  final sent = <SupportTicket>[];

  @override
  Future<SupportReceipt> submit(SupportTicket ticket) async {
    if (failure != null) throw SupportApiException(failure!, 'fake');
    sent.add(ticket);
    return const SupportReceipt(id: 'x', folio: 'SOP-000042');
  }
}

Future<void> _open(WidgetTester tester, SupportApi api) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
      ],
      home: SupportScreen(api: api),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String option) async {
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

const _calc = 'Los cálculos se muestran incorrectos';
const _alert =
    'No sale la alerta en DiDi o Uber aunque ViajeOK está encendido';
const _other = 'Otro problema';

void main() {
  testWidgets('asks to pick a problem first', (tester) async {
    final api = _FakeApi();
    await _open(tester, api);

    expect(find.text('Modelo del celular'), findsNothing);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona qué problema tienes'), findsOneWidget);
    expect(api.sent, isEmpty);
  });

  testWidgets('calculation problem asks for model, screenshots and email', (
    tester,
  ) async {
    final api = _FakeApi();
    await _open(tester, api);
    await _choose(tester, _calc);

    expect(find.text('Modelo del celular'), findsOneWidget);
    expect(find.text('Capturas de pantalla'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('¿Qué problema tuviste?'), findsNothing);

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio'), findsNWidgets(2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Realme 12 Pro');
    await tester.enterText(fields.at(1), 'no-es-correo');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un correo válido'), findsOneWidget);
    expect(api.sent, isEmpty);

    await tester.enterText(fields.at(1), ' chofer@correo.com ');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Estamos revisando la información'), findsOneWidget);
    expect(
      find.text(
        'El tiempo promedio de respuesta es de 12 horas.\n\n'
        'Tu folio es SOP-000042.',
      ),
      findsOneWidget,
    );
    final ticket = api.sent.single;
    expect(ticket.issue, SupportIssue.wrongCalculation);
    expect(ticket.phoneModel, 'Realme 12 Pro');
    expect(ticket.email, 'chofer@correo.com');
    expect(ticket.message, isNull);
  });

  testWidgets('alert problem uses the same detailed fields', (tester) async {
    final api = _FakeApi();
    await _open(tester, api);
    await _choose(tester, _alert);

    expect(find.text('Modelo del celular'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
  });

  testWidgets('other problem asks what happened and an email', (tester) async {
    final api = _FakeApi();
    await _open(tester, api);
    await _choose(tester, _other);

    expect(find.text('¿Qué problema tuviste?'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Modelo del celular'), findsNothing);
    expect(find.text('Capturas de pantalla'), findsNothing);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'La app se cierra sola');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio'), findsOneWidget);
    expect(api.sent, isEmpty);

    await tester.enterText(fields.at(1), 'chofer@correo.com');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Estamos revisando la información'), findsOneWidget);
    final ticket = api.sent.single;
    expect(ticket.issue, SupportIssue.other);
    expect(ticket.message, 'La app se cierra sola');
    expect(ticket.email, 'chofer@correo.com');
    expect(ticket.phoneModel, isNull);
    expect(ticket.screenshotPaths, isEmpty);
  });

  testWidgets('a failed send keeps the form and says so', (tester) async {
    await _open(tester, _FakeApi(failure: SupportFailure.unavailable));
    await _choose(tester, _other);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Algo falló');
    await tester.enterText(fields.at(1), 'chofer@correo.com');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo enviar. Revisa tu conexión e inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Estamos revisando la información'), findsNothing);
    expect(find.text('Algo falló'), findsOneWidget);
  });

  testWidgets('too many reports gets its own message', (tester) async {
    await _open(tester, _FakeApi(failure: SupportFailure.rateLimited));
    await _choose(tester, _other);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Algo falló');
    await tester.enterText(fields.at(1), 'chofer@correo.com');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enviaste demasiados reportes. Intenta de nuevo más tarde.'),
      findsOneWidget,
    );
  });
}
