// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get btnSetupNow => 'Configurar ahora';

  @override
  String get btnNext => 'Siguiente';

  @override
  String get btnOpenSettings => 'Abrir configuración';

  @override
  String get btnStartEarning => '¡Empezar a ganar!';

  @override
  String welcomeTitle(String appName) {
    return '¡Bienvenido a\n$appName!';
  }

  @override
  String get welcomeText =>
      'Vamos a configurarlo en 1 minuto\npara que funcione perfecto mientras manejas.';

  @override
  String get featureTripAnalysis => 'Análisis de cada viaje';

  @override
  String get featureInYourApps => 'En tus apps de transporte favoritas';

  @override
  String get featurePopupOverApp => 'Popup sobre tu app de transporte';

  @override
  String get featureWithoutLeaving => 'Sin salir de tu app de trabajo';

  @override
  String get featureGreenRed => 'Verde o rojo al instante';

  @override
  String get featureByFilters => 'Según tus filtros de ganancia';

  @override
  String get overlayTitle => 'Superposición sobre apps';

  @override
  String get overlayText =>
      'Permite mostrar el popup de ganancias encima de tus apps de transporte mientras conduces, sin tener que cambiar de app.';

  @override
  String get overlayGranted => 'Permiso concedido — el popup podrá aparecer.';

  @override
  String get overlayRequired =>
      'Este permiso es obligatorio. Sin él, el popup no puede aparecer.';

  @override
  String get overlayPreviewTitle => 'Así se verá mientras manejas:';

  @override
  String get overlayPreviewText =>
      '← Se pone verde si el viaje conviene y rojo si no, según tus filtros.';

  @override
  String get doneTitle => '¡Todo listo!';

  @override
  String doneText(String appName) {
    return '$appName está configurado.\nPresiona ► Reproducir y empieza a analizar tus viajes.';
  }

  @override
  String get featureAutoAnalysis => 'Análisis automático de viajes';

  @override
  String get featurePopupOverApps => 'Popup encima de tus apps';

  @override
  String get featureWhileDriving => 'Funciona mientras manejas';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabConfig => 'Config';

  @override
  String get tabSupport => 'Soporte';

  @override
  String get supportText => 'Ayuda y contacto. Próximamente.';

  @override
  String get panelReady => 'Listo para iniciar';

  @override
  String get panelRunning => 'Analizando viajes…';

  @override
  String get panelTapToStart => 'Toca para iniciar el análisis';

  @override
  String get panelTapToStop => 'Toca para detener el análisis';

  @override
  String get statTotal => 'Total';

  @override
  String get statAccept => 'Aceptar';

  @override
  String get statReject => 'Rechazar';

  @override
  String get filtersTitle => 'Filtros inteligentes';

  @override
  String filtersActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activos',
      one: '1 activo',
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
  String get filterOff => 'Desactivado';

  @override
  String get configAppsTitle => 'Aplicaciones monitoreadas';

  @override
  String get configAppsSubtitle => 'Toca para activar o desactivar el cálculo';

  @override
  String get dialogCancel => 'Cancelar';

  @override
  String get dialogEnableServiceTitle => 'Activa la Lectura de pantalla';

  @override
  String get dialogEnableServiceText =>
      'En Ajustes → Accesibilidad, busca \"Análisis Viaje – Lectura de viajes\" y actívalo. Después regresa y presiona ▶.\n\nSi aparece como restringido: Ajustes → Apps → Análisis Viaje → ⋮ → Permitir ajustes restringidos.';

  @override
  String get readingTitle => 'Lectura de pantalla';

  @override
  String readingText(String appName) {
    return '$appName lee el precio y los km de cada oferta en DiDi y Uber para decirte si conviene. Se activa una sola vez y sigue funcionando aunque bloquees el teléfono.';
  }

  @override
  String get readingEnabled => 'Lectura de pantalla activada — todo listo.';

  @override
  String get readingRequired =>
      'Este permiso es obligatorio. Sin él, la app no puede leer las ofertas.';
}
