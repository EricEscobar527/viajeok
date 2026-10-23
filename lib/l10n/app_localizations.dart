import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a\n{appName}'**
  String welcomeTitle(String appName);

  /// No description provided for @welcomeText.
  ///
  /// In es, this message translates to:
  /// **'Te decimos al instante si una oferta de DiDi o Uber te conviene.'**
  String get welcomeText;

  /// No description provided for @featureReadTitle.
  ///
  /// In es, this message translates to:
  /// **'Lee cada oferta de DiDi y Uber'**
  String get featureReadTitle;

  /// No description provided for @featureReadText.
  ///
  /// In es, this message translates to:
  /// **'Precio, distancia y tiempo, sin que hagas nada'**
  String get featureReadText;

  /// No description provided for @featureVerdictTitle.
  ///
  /// In es, this message translates to:
  /// **'Verde o rojo al instante'**
  String get featureVerdictTitle;

  /// No description provided for @featureVerdictText.
  ///
  /// In es, this message translates to:
  /// **'Según los mínimos que tú defines'**
  String get featureVerdictText;

  /// No description provided for @featureOverlayTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin salir de tu app'**
  String get featureOverlayTitle;

  /// No description provided for @featureOverlayText.
  ///
  /// In es, this message translates to:
  /// **'Un aviso pequeño encima de la oferta'**
  String get featureOverlayText;

  /// No description provided for @btnStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get btnStart;

  /// No description provided for @supportTitle.
  ///
  /// In es, this message translates to:
  /// **'Soporte'**
  String get supportTitle;

  /// No description provided for @btnStartAnalysis.
  ///
  /// In es, this message translates to:
  /// **'Iniciar análisis'**
  String get btnStartAnalysis;

  /// No description provided for @btnStopAnalysis.
  ///
  /// In es, this message translates to:
  /// **'Detener análisis'**
  String get btnStopAnalysis;

  /// No description provided for @panelHintIdle.
  ///
  /// In es, this message translates to:
  /// **'Después abre DiDi o Uber; te avisamos en cada oferta.'**
  String get panelHintIdle;

  /// No description provided for @panelRunning.
  ///
  /// In es, this message translates to:
  /// **'Analizando ofertas'**
  String get panelRunning;

  /// No description provided for @panelHintRunning.
  ///
  /// In es, this message translates to:
  /// **'Abre DiDi o Uber y espera tus ofertas.'**
  String get panelHintRunning;

  /// No description provided for @filtersTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis mínimos'**
  String get filtersTitle;

  /// No description provided for @filtersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La oferta sale en verde si cumple todos los que actives.'**
  String get filtersSubtitle;

  /// No description provided for @filtersActive.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Ninguno activo} =1{1 activo} other{{count} activos}}'**
  String filtersActive(int count);

  /// No description provided for @filterPerHour.
  ///
  /// In es, this message translates to:
  /// **'Por hora'**
  String get filterPerHour;

  /// No description provided for @filterPerKm.
  ///
  /// In es, this message translates to:
  /// **'Por km'**
  String get filterPerKm;

  /// No description provided for @filterMaxPickup.
  ///
  /// In es, this message translates to:
  /// **'Pickup máx.'**
  String get filterMaxPickup;

  /// No description provided for @filterPerHourHint.
  ///
  /// In es, this message translates to:
  /// **'Ganancia mínima por hora, contando el tiempo para recoger.'**
  String get filterPerHourHint;

  /// No description provided for @filterPerKmHint.
  ///
  /// In es, this message translates to:
  /// **'Ganancia mínima por km, contando los km para recoger.'**
  String get filterPerKmHint;

  /// No description provided for @filterMaxPickupHint.
  ///
  /// In es, this message translates to:
  /// **'Distancia máxima que manejas sin cobrar para recoger.'**
  String get filterMaxPickupHint;

  /// No description provided for @filterMaxPickupValue.
  ///
  /// In es, this message translates to:
  /// **'{value} km máx.'**
  String filterMaxPickupValue(String value);

  /// No description provided for @filterOff.
  ///
  /// In es, this message translates to:
  /// **'Apagado'**
  String get filterOff;

  /// No description provided for @dialogCancel.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get dialogCancel;

  /// No description provided for @supportIssueLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Qué problema tienes?'**
  String get supportIssueLabel;

  /// No description provided for @supportIssueWrongCalculation.
  ///
  /// In es, this message translates to:
  /// **'Los cálculos se muestran incorrectos'**
  String get supportIssueWrongCalculation;

  /// No description provided for @supportIssueAlertNotShown.
  ///
  /// In es, this message translates to:
  /// **'No sale la alerta en DiDi o Uber aunque ViajeOK está encendido'**
  String get supportIssueAlertNotShown;

  /// No description provided for @supportIssueOther.
  ///
  /// In es, this message translates to:
  /// **'Otro problema'**
  String get supportIssueOther;

  /// No description provided for @supportIssueRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona qué problema tienes'**
  String get supportIssueRequired;

  /// No description provided for @supportPhoneModel.
  ///
  /// In es, this message translates to:
  /// **'Modelo del celular'**
  String get supportPhoneModel;

  /// No description provided for @supportPhoneModelHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Samsung Galaxy A54'**
  String get supportPhoneModelHint;

  /// No description provided for @supportScreenshots.
  ///
  /// In es, this message translates to:
  /// **'Capturas de pantalla'**
  String get supportScreenshots;

  /// No description provided for @supportAddScreenshot.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get supportAddScreenshot;

  /// No description provided for @supportRemoveScreenshot.
  ///
  /// In es, this message translates to:
  /// **'Quitar captura'**
  String get supportRemoveScreenshot;

  /// No description provided for @supportScreenshotsHint.
  ///
  /// In es, this message translates to:
  /// **'Hasta {max} imágenes. Ayudan a encontrar el problema más rápido.'**
  String supportScreenshotsHint(int max);

  /// No description provided for @supportEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get supportEmail;

  /// No description provided for @supportEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tucorreo@ejemplo.com'**
  String get supportEmailHint;

  /// No description provided for @supportEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un correo válido'**
  String get supportEmailInvalid;

  /// No description provided for @supportDescription.
  ///
  /// In es, this message translates to:
  /// **'¿Qué problema tuviste?'**
  String get supportDescription;

  /// No description provided for @supportDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué pasó'**
  String get supportDescriptionHint;

  /// No description provided for @supportFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get supportFieldRequired;

  /// No description provided for @supportSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get supportSend;

  /// No description provided for @supportSending.
  ///
  /// In es, this message translates to:
  /// **'Enviando…'**
  String get supportSending;

  /// No description provided for @supportSendError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar. Revisa tu conexión e inténtalo de nuevo.'**
  String get supportSendError;

  /// No description provided for @supportSentTitle.
  ///
  /// In es, this message translates to:
  /// **'Estamos revisando la información'**
  String get supportSentTitle;

  /// No description provided for @supportSentText.
  ///
  /// In es, this message translates to:
  /// **'El tiempo promedio de respuesta es de 12 horas.'**
  String get supportSentText;

  /// No description provided for @supportSentOk.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get supportSentOk;

  /// No description provided for @serviceOnTitle.
  ///
  /// In es, this message translates to:
  /// **'Lectura de pantalla activa'**
  String get serviceOnTitle;

  /// No description provided for @serviceOnText.
  ///
  /// In es, this message translates to:
  /// **'Si una app de banco no te deja entrar, desactívala aquí.'**
  String get serviceOnText;

  /// No description provided for @btnDisableService.
  ///
  /// In es, this message translates to:
  /// **'Desactivar'**
  String get btnDisableService;

  /// No description provided for @dialogDisableServiceTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Desactivar la Lectura de pantalla?'**
  String get dialogDisableServiceTitle;

  /// No description provided for @dialogDisableServiceText.
  ///
  /// In es, this message translates to:
  /// **'Algunas apps de banco (como Nu) no abren mientras está activa. Al desactivarla también se detiene el análisis.\n\nPara volver a usarlo, presiona Iniciar análisis y actívala otra vez en Ajustes.'**
  String get dialogDisableServiceText;

  /// No description provided for @serviceDisabledNotice.
  ///
  /// In es, this message translates to:
  /// **'Lectura de pantalla desactivada. Ya puedes abrir tu app de banco.'**
  String get serviceDisabledNotice;

  /// No description provided for @supportSentFolio.
  ///
  /// In es, this message translates to:
  /// **'Tu folio es {folio}.'**
  String supportSentFolio(String folio);

  /// No description provided for @supportSendRateLimited.
  ///
  /// In es, this message translates to:
  /// **'Enviaste demasiados reportes. Intenta de nuevo más tarde.'**
  String get supportSendRateLimited;

  /// No description provided for @supportSendInvalid.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar: revisa los datos y las imágenes.'**
  String get supportSendInvalid;

  /// No description provided for @supportImageFormat.
  ///
  /// In es, this message translates to:
  /// **'Algunas imágenes no se agregaron: usa capturas JPG o PNG.'**
  String get supportImageFormat;

  /// No description provided for @disclosureTitle.
  ///
  /// In es, this message translates to:
  /// **'Antes de activar'**
  String get disclosureTitle;

  /// No description provided for @disclosureIntro.
  ///
  /// In es, this message translates to:
  /// **'ViajeOK usa el Servicio de Accesibilidad de Android para leer la información de las ofertas de viaje que aparecen en tu pantalla en Uber y DiDi.'**
  String get disclosureIntro;

  /// No description provided for @disclosureDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Qué datos lee'**
  String get disclosureDataTitle;

  /// No description provided for @disclosureDataText.
  ///
  /// In es, this message translates to:
  /// **'Mientras el análisis está activo y Uber o DiDi están en pantalla, ViajeOK captura y procesa en tu teléfono la pantalla de esas apps para extraer los datos de la oferta de viaje: tarifa, distancia, tiempo estimado y zona de origen y destino. Todo lo demás que aparezca en la pantalla se descarta. No captura otras apps.'**
  String get disclosureDataText;

  /// No description provided for @disclosureUseTitle.
  ///
  /// In es, this message translates to:
  /// **'Para qué los usa'**
  String get disclosureUseTitle;

  /// No description provided for @disclosureUseText.
  ///
  /// In es, this message translates to:
  /// **'Para calcular al instante cuánto ganarías por kilómetro y mostrarte si el viaje te conviene según tus criterios. ViajeOK no acepta, rechaza ni toca nada en Uber o DiDi; la decisión siempre es tuya.'**
  String get disclosureUseText;

  /// No description provided for @disclosureStorageTitle.
  ///
  /// In es, this message translates to:
  /// **'Si se guardan o comparten'**
  String get disclosureStorageTitle;

  /// No description provided for @disclosureStorageText.
  ///
  /// In es, this message translates to:
  /// **'La información se procesa en tu teléfono. No se envía a nuestros servidores ni se comparte con terceros. Solo se guarda en tu dispositivo un historial de viajes evaluados, que puedes borrar cuando quieras.'**
  String get disclosureStorageText;

  /// No description provided for @disclosureControlTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo desactivarlo'**
  String get disclosureControlTitle;

  /// No description provided for @disclosureControlText.
  ///
  /// In es, this message translates to:
  /// **'Puedes desactivar el permiso en cualquier momento en Ajustes > Accesibilidad > ViajeOK. Si lo desactivas, la app deja de evaluar viajes.'**
  String get disclosureControlText;

  /// No description provided for @disclosureAccept.
  ///
  /// In es, this message translates to:
  /// **'Acepto'**
  String get disclosureAccept;

  /// No description provided for @disclosureDecline.
  ///
  /// In es, this message translates to:
  /// **'No acepto'**
  String get disclosureDecline;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
