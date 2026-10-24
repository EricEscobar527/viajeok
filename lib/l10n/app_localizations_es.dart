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
  String get supportIssueLabel => '¿Qué problema tienes?';

  @override
  String get supportIssueWrongCalculation =>
      'Los cálculos se muestran incorrectos';

  @override
  String get supportIssueAlertNotShown =>
      'No sale la alerta en DiDi o Uber aunque ViajeOK está encendido';

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

  @override
  String get disclosureTitle => 'Antes de activar';

  @override
  String get disclosureIntro =>
      'ViajeOK usa el Servicio de Accesibilidad de Android para leer la información de las ofertas de viaje que aparecen en tu pantalla en Uber y DiDi.';

  @override
  String get disclosureDataTitle => 'Qué datos lee';

  @override
  String get disclosureDataText =>
      'Mientras el análisis está activo y Uber o DiDi están en pantalla, ViajeOK captura y procesa en tu teléfono la pantalla de esas apps para extraer los datos de la oferta de viaje: tarifa, distancia, tiempo estimado y zona de origen y destino. Todo lo demás que aparezca en la pantalla se descarta. No captura otras apps.';

  @override
  String get disclosureUseTitle => 'Para qué los usa';

  @override
  String get disclosureUseText =>
      'Para calcular al instante cuánto ganarías por kilómetro y mostrarte si el viaje te conviene según tus criterios. ViajeOK no acepta, rechaza ni toca nada en Uber o DiDi; la decisión siempre es tuya.';

  @override
  String get disclosureStorageTitle => 'Si se guardan o comparten';

  @override
  String get disclosureStorageText =>
      'La información se procesa en tu teléfono. No se envía a nuestros servidores ni se comparte con terceros. Los datos de las ofertas no se guardan: se descartan al cerrarse la oferta.';

  @override
  String get disclosureControlTitle => 'Cómo desactivarlo';

  @override
  String get disclosureControlText =>
      'Puedes desactivar el permiso en cualquier momento en Ajustes > Accesibilidad > ViajeOK. Si lo desactivas, la app deja de evaluar viajes.';

  @override
  String get disclosureAccept => 'Acepto';

  @override
  String get disclosureDecline => 'No acepto';

  @override
  String get subTitle => 'Suscripción ViajeOK';

  @override
  String get subSubtitle =>
      'Sigue sabiendo al instante si cada viaje te conviene.';

  @override
  String get subFeatureAnalysis => 'Alerta en cada oferta';

  @override
  String get subFeatureAnalysisText =>
      'Verde o roja sobre DiDi y Uber, según tus mínimos.';

  @override
  String get subFeatureFilters => 'Tus mínimos';

  @override
  String get subFeatureFiltersText => 'Por hora, por km y pickup máximo.';

  @override
  String get subFeatureCancel => 'Sin plazos forzosos';

  @override
  String get subFeatureCancelText =>
      'Cancela cuando quieras desde Google Play.';

  @override
  String subPricePerMonth(String price) {
    return '$price al mes';
  }

  @override
  String subTrialDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días gratis',
      one: '1 día gratis',
    );
    return '$_temp0';
  }

  @override
  String subTrialWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas gratis',
      one: '1 semana gratis',
    );
    return '$_temp0';
  }

  @override
  String subTrialMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses gratis',
      one: '1 mes gratis',
    );
    return '$_temp0';
  }

  @override
  String subTrialThen(String price) {
    return 'Después, $price al mes';
  }

  @override
  String get btnStartTrial => 'Empezar prueba gratis';

  @override
  String get btnSubscribe => 'Suscribirme';

  @override
  String get btnRestorePurchase => 'Restaurar compra';

  @override
  String get btnManageSubscription => 'Administrar';

  @override
  String get btnRetry => 'Reintentar';

  @override
  String get subRenewalNote =>
      'Se renueva automáticamente cada mes hasta que la canceles. Cancela cuando quieras en Google Play › Pagos y suscripciones; si cancelas durante la prueba gratis, no se te cobra nada.';

  @override
  String get subUnavailable =>
      'No se pudo conectar con Google Play. Revisa tu conexión e intenta de nuevo.';

  @override
  String get subErrorPurchase =>
      'No se pudo completar la compra. Intenta de nuevo.';

  @override
  String get subErrorVerify =>
      'Google Play registró tu pago, pero aún no pudimos confirmarlo. Toca Restaurar compra en un momento.';

  @override
  String subActiveUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Suscripción activa hasta el $dateString';
  }

  @override
  String subTrialUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Prueba gratis hasta el $dateString';
  }

  @override
  String get subActive => 'Suscripción activa';

  @override
  String get updateTitle => 'Actualiza ViajeOK';

  @override
  String get updateText =>
      'Esta versión ya no es compatible. Descarga la más reciente en Google Play para seguir usando la app.';

  @override
  String get btnUpdate => 'Actualizar';

  @override
  String get privacyPolicy => 'Política de privacidad';
}
