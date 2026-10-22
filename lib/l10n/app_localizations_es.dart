// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String welcomeTitle(String appName) {
    return 'Bienvenido a\n$appName';
  }

  @override
  String get welcomeText =>
      'Te decimos al instante si una oferta de DiDi o Uber te conviene.';

  @override
  String get featureReadTitle => 'Lee cada oferta de DiDi y Uber';

  @override
  String get featureReadText =>
      'Precio, distancia y tiempo, sin que hagas nada';

  @override
  String get featureVerdictTitle => 'Verde o rojo al instante';

  @override
  String get featureVerdictText => 'Según los mínimos que tú defines';

  @override
  String get featureOverlayTitle => 'Sin salir de tu app';

  @override
  String get featureOverlayText => 'Un aviso pequeño encima de la oferta';

  @override
  String get btnStart => 'Empezar';

  @override
  String get supportTitle => 'Soporte';

  @override
  String get btnStartAnalysis => 'Iniciar análisis';

  @override
  String get btnStopAnalysis => 'Detener análisis';

  @override
  String get panelHintIdle =>
      'Después abre DiDi o Uber; te avisamos en cada oferta.';

  @override
  String get panelRunning => 'Analizando ofertas';

  @override
  String get panelHintRunning => 'Abre DiDi o Uber y espera tus ofertas.';

  @override
  String get filtersTitle => 'Mis mínimos';

  @override
  String get filtersSubtitle =>
      'La oferta sale en verde si cumple todos los que actives.';

  @override
  String filtersActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activos',
      one: '1 activo',
      zero: 'Ninguno activo',
    );
    return '$_temp0';
  }

  @override
  String get filterPerHour => 'Por hora';

  @override
  String get filterPerKm => 'Por km';

  @override
  String get filterMaxPickup => 'Pickup máx.';

  @override
  String get filterPerHourHint =>
      'Ganancia mínima por hora, contando el tiempo para recoger.';

  @override
  String get filterPerKmHint =>
      'Ganancia mínima por km, contando los km para recoger.';

  @override
  String get filterMaxPickupHint =>
      'Distancia máxima que manejas sin cobrar para recoger.';

  @override
  String filterMaxPickupValue(String value) {
    return '$value km máx.';
  }

  @override
  String get filterOff => 'Apagado';

  @override
  String get dialogCancel => 'Ahora no';

  @override
  String get btnOpenSettings => 'Abrir ajustes';

  @override
  String get dialogEnableServiceTitle => 'Activa la Lectura de pantalla';

  @override
  String get dialogEnableServiceText =>
      'Es lo que permite leer las ofertas de DiDi y Uber. Solo se activa una vez.\n\nEn Ajustes → Accesibilidad, busca \"Análisis Viaje – Lectura de viajes\" y actívalo. Después regresa y presiona Iniciar.\n\nSi aparece como restringido: Ajustes → Apps → Análisis Viaje → ⋮ → Permitir ajustes restringidos.';

  @override
  String get supportIssueLabel => '¿Qué problema tienes?';

  @override
  String get supportIssueWrongCalculation =>
      'Los cálculos se muestran incorrectos';

  @override
  String get supportIssueAlertNotShown =>
      'No sale la alerta en DiDi o Uber aunque Análisis Viaje está encendido';

  @override
  String get supportIssueOther => 'Otro problema';

  @override
  String get supportIssueRequired => 'Selecciona qué problema tienes';

  @override
  String get supportPhoneModel => 'Modelo del celular';

  @override
  String get supportPhoneModelHint => 'Ej. Samsung Galaxy A54';

  @override
  String get supportScreenshots => 'Capturas de pantalla';

  @override
  String get supportAddScreenshot => 'Agregar';

  @override
  String get supportRemoveScreenshot => 'Quitar captura';

  @override
  String supportScreenshotsHint(int max) {
    return 'Hasta $max imágenes. Ayudan a encontrar el problema más rápido.';
  }

  @override
  String get supportEmail => 'Correo electrónico';

  @override
  String get supportEmailHint => 'tucorreo@ejemplo.com';

  @override
  String get supportEmailInvalid => 'Escribe un correo válido';

  @override
  String get supportDescription => '¿Qué problema tuviste?';

  @override
  String get supportDescriptionHint => 'Cuéntanos qué pasó';

  @override
  String get supportFieldRequired => 'Este campo es obligatorio';

  @override
  String get supportSend => 'Enviar';

  @override
  String get supportSending => 'Enviando…';

  @override
  String get supportSendError =>
      'No se pudo enviar. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get supportSentTitle => 'Estamos revisando la información';

  @override
  String get supportSentText =>
      'El tiempo promedio de respuesta es de 12 horas.';

  @override
  String get supportSentOk => 'Entendido';

  @override
  String get serviceOnTitle => 'Lectura de pantalla activa';

  @override
  String get serviceOnText =>
      'Si una app de banco no te deja entrar, desactívala aquí.';

  @override
  String get btnDisableService => 'Desactivar';

  @override
  String get dialogDisableServiceTitle => '¿Desactivar la Lectura de pantalla?';

  @override
  String get dialogDisableServiceText =>
      'Algunas apps de banco (como Nu) no abren mientras está activa. Al desactivarla también se detiene el análisis.\n\nPara volver a usarlo, presiona Iniciar análisis y actívala otra vez en Ajustes.';

  @override
  String get serviceDisabledNotice =>
      'Lectura de pantalla desactivada. Ya puedes abrir tu app de banco.';

  @override
  String supportSentFolio(String folio) {
    return 'Tu folio es $folio.';
  }

  @override
  String get supportSendRateLimited =>
      'Enviaste demasiados reportes. Intenta de nuevo más tarde.';

  @override
  String get supportSendInvalid =>
      'No se pudo enviar: revisa los datos y las imágenes.';

  @override
  String get supportImageFormat =>
      'Algunas imágenes no se agregaron: usa capturas JPG o PNG.';
}
