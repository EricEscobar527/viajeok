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

  /// No description provided for @btnSetupNow.
  ///
  /// In es, this message translates to:
  /// **'Configurar ahora'**
  String get btnSetupNow;

  /// No description provided for @btnNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get btnNext;

  /// No description provided for @btnOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir configuración'**
  String get btnOpenSettings;

  /// No description provided for @btnStartEarning.
  ///
  /// In es, this message translates to:
  /// **'¡Empezar a ganar!'**
  String get btnStartEarning;

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a\n{appName}!'**
  String welcomeTitle(String appName);

  /// No description provided for @welcomeText.
  ///
  /// In es, this message translates to:
  /// **'Vamos a configurarlo en 1 minuto\npara que funcione perfecto mientras manejas.'**
  String get welcomeText;

  /// No description provided for @featureTripAnalysis.
  ///
  /// In es, this message translates to:
  /// **'Análisis de cada viaje'**
  String get featureTripAnalysis;

  /// No description provided for @featureInYourApps.
  ///
  /// In es, this message translates to:
  /// **'En tus apps de transporte favoritas'**
  String get featureInYourApps;

  /// No description provided for @featurePopupOverApp.
  ///
  /// In es, this message translates to:
  /// **'Popup sobre tu app de transporte'**
  String get featurePopupOverApp;

  /// No description provided for @featureWithoutLeaving.
  ///
  /// In es, this message translates to:
  /// **'Sin salir de tu app de trabajo'**
  String get featureWithoutLeaving;

  /// No description provided for @featureGreenRed.
  ///
  /// In es, this message translates to:
  /// **'Verde o rojo al instante'**
  String get featureGreenRed;

  /// No description provided for @featureByFilters.
  ///
  /// In es, this message translates to:
  /// **'Según tus filtros de ganancia'**
  String get featureByFilters;

  /// No description provided for @overlayTitle.
  ///
  /// In es, this message translates to:
  /// **'Superposición sobre apps'**
  String get overlayTitle;

  /// No description provided for @overlayText.
  ///
  /// In es, this message translates to:
  /// **'Permite mostrar el popup de ganancias encima de tus apps de transporte mientras conduces, sin tener que cambiar de app.'**
  String get overlayText;

  /// No description provided for @overlayGranted.
  ///
  /// In es, this message translates to:
  /// **'Permiso concedido — el popup podrá aparecer.'**
  String get overlayGranted;

  /// No description provided for @overlayRequired.
  ///
  /// In es, this message translates to:
  /// **'Este permiso es obligatorio. Sin él, el popup no puede aparecer.'**
  String get overlayRequired;

  /// No description provided for @overlayPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Así se verá mientras manejas:'**
  String get overlayPreviewTitle;

  /// No description provided for @overlayPreviewText.
  ///
  /// In es, this message translates to:
  /// **'← Se pone verde si el viaje conviene y rojo si no, según tus filtros.'**
  String get overlayPreviewText;

  /// No description provided for @doneTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Todo listo!'**
  String get doneTitle;

  /// No description provided for @doneText.
  ///
  /// In es, this message translates to:
  /// **'{appName} está configurado.\nPresiona ► Reproducir y empieza a analizar tus viajes.'**
  String doneText(String appName);

  /// No description provided for @featureAutoAnalysis.
  ///
  /// In es, this message translates to:
  /// **'Análisis automático de viajes'**
  String get featureAutoAnalysis;

  /// No description provided for @featurePopupOverApps.
  ///
  /// In es, this message translates to:
  /// **'Popup encima de tus apps'**
  String get featurePopupOverApps;

  /// No description provided for @featureWhileDriving.
  ///
  /// In es, this message translates to:
  /// **'Funciona mientras manejas'**
  String get featureWhileDriving;

  /// No description provided for @tabHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get tabHome;

  /// No description provided for @tabConfig.
  ///
  /// In es, this message translates to:
  /// **'Config'**
  String get tabConfig;

  /// No description provided for @tabSupport.
  ///
  /// In es, this message translates to:
  /// **'Soporte'**
  String get tabSupport;

  /// No description provided for @supportText.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y contacto. Próximamente.'**
  String get supportText;

  /// No description provided for @panelReady.
  ///
  /// In es, this message translates to:
  /// **'Listo para iniciar'**
  String get panelReady;

  /// No description provided for @panelRunning.
  ///
  /// In es, this message translates to:
  /// **'Analizando viajes…'**
  String get panelRunning;

  /// No description provided for @panelTapToStart.
  ///
  /// In es, this message translates to:
  /// **'Toca para iniciar el análisis'**
  String get panelTapToStart;

  /// No description provided for @panelTapToStop.
  ///
  /// In es, this message translates to:
  /// **'Toca para detener el análisis'**
  String get panelTapToStop;

  /// No description provided for @statTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @statAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get statAccept;

  /// No description provided for @statReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get statReject;

  /// No description provided for @filtersTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtros inteligentes'**
  String get filtersTitle;

  /// No description provided for @filtersActive.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 activo} other{{count} activos}}'**
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
  /// **'Desactivado'**
  String get filterOff;

  /// No description provided for @configAppsTitle.
  ///
  /// In es, this message translates to:
  /// **'Aplicaciones monitoreadas'**
  String get configAppsTitle;

  /// No description provided for @configAppsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Toca para activar o desactivar el cálculo'**
  String get configAppsSubtitle;

  /// No description provided for @dialogCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get dialogCancel;

  /// No description provided for @dialogEnableServiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Activa la Lectura de pantalla'**
  String get dialogEnableServiceTitle;

  /// No description provided for @dialogEnableServiceText.
  ///
  /// In es, this message translates to:
  /// **'En Ajustes → Accesibilidad, busca \"Análisis Viaje – Lectura de viajes\" y actívalo. Después regresa y presiona ▶.\n\nSi aparece como restringido: Ajustes → Apps → Análisis Viaje → ⋮ → Permitir ajustes restringidos.'**
  String get dialogEnableServiceText;

  /// No description provided for @readingTitle.
  ///
  /// In es, this message translates to:
  /// **'Lectura de pantalla'**
  String get readingTitle;

  /// No description provided for @readingText.
  ///
  /// In es, this message translates to:
  /// **'{appName} lee el precio y los km de cada oferta en DiDi y Uber para decirte si conviene. Se activa una sola vez y sigue funcionando aunque bloquees el teléfono.'**
  String readingText(String appName);

  /// No description provided for @readingEnabled.
  ///
  /// In es, this message translates to:
  /// **'Lectura de pantalla activada — todo listo.'**
  String get readingEnabled;

  /// No description provided for @readingRequired.
  ///
  /// In es, this message translates to:
  /// **'Este permiso es obligatorio. Sin él, la app no puede leer las ofertas.'**
  String get readingRequired;
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
