# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`analisis_viaje` is an Android-first Flutter app for ride-hailing drivers, modeled on "Ruta Rentable": while Uber/DiDi is open, it reads the trip offer on screen, computes $/km and $/h, and shows a popup over the ride app whose border is green (worth it) or red (not), based on the user's filters. UI text is in Spanish. The brand uses a grayish-black background with white as the accent (`AppColors.accent`); `AppColors.green`/`red` are reserved for accept/reject meaning (Aceptar counter, popup preview), so don't use green as a general highlight. Tabs: Inicio, Config, Soporte. The user removed Billetera, the language selector, the country chip, Cámara, Premium, the header menu and the Turbo filter; don't add them back unless asked.

Current state: works end to end on a real phone with DiDi Conductor via "Lectura de pantalla" (AccessibilityService + screenshot OCR). The user dropped "Compartir pantalla" (MediaProjection) for now; it may be needed later only if Google Play rejects the accessibility-service approach, so don't re-add it unprompted.

## Commands

```bash
flutter pub get
flutter run                                       # needs an Android device/emulator for the native bits
flutter analyze
dart format lib test
flutter test
flutter test test/trip_filters_test.dart          # single file
flutter test --plain-name "rejects and reports"   # single test by name
flutter build apk --debug

# Kotlin unit tests (parser/evaluator); Gradle needs JDK 17, e.g. Android Studio's:
cd android && JAVA_HOME="C:\Program Files\Android\Android Studio\jbr" ./gradlew.bat :app:testDebugUnitTest

# What the service reads on the phone (debug builds log every screen containing "km"):
adb logcat -s AnalisisViaje:D
```

## Architecture

- **Startup flow** (`lib/main.dart`): `main()` loads `AppPrefs` before `runApp`, then `SplashScreen` → `_AfterSplash`, which shows `OnboardingScreen` until `onboarding_done` is set, then `HomeShell` on every later launch.
- **Splash** (`lib/splash_screen.dart`): reveals `AppInfo.name` in white with a left-to-right gradient sweep. No logo is shown anywhere in the app (the user asked to drop it; the PNG remains in `assets/images/` unused). `AppColors.background` (`#121212`) must match the Android native launch color (`android/app/src/main/res/drawable*/launch_background.xml`) or a flash appears.
- **Onboarding** (`lib/onboarding/`): welcome → overlay permission → enable Lectura de pantalla (the accessibility service) → done. Notification and battery-optimization steps from the original app were intentionally left out. Both permission steps re-check on `AppLifecycleState.resumed`, since the user grants them in system settings.
- **Native bridge**: `lib/platform/permissions.dart` ↔ `MainActivity.kt` over the `analisis_viaje/permissions` MethodChannel (`canDrawOverlays`, `openOverlaySettings`). Add new Android-only calls there instead of pulling in a plugin for one call.
- **Trip reading** (`android/app/src/main/kotlin/.../reader/`): `TripReaderService` is an AccessibilityService limited to the ride-app packages in `res/xml/trip_reader_service.xml`. While analysis runs and a ride app is in front, it re-reads the screen every `POLL_MS` (DiDi fires no accessibility events while an offer is shown, so events alone aren't enough) plus on events. Each read first tries the apps' accessibility text; if `TripParser` finds no offer there, `ScreenOcr` takes an accessibility screenshot (API 30+, `canTakeScreenshot`, ~1/s limit), crops the top 20%, halves it, runs on-device ML Kit OCR and drops lines overlapping our own popup, then feeds the lines to the same parser. Verified on a real phone: DiDi Conductor's offer card is Flutter with no accessibility text and its view tree gives no reliable "offer showing" signal (the `flutter_deal_gesture_container` id is present while idle and disappears during offers), so OCR is what actually reads DiDi. `TripParser` extracts fare + two "X min (Y km)" legs (first = pickup, second = trip; fare prefers the "Aceptar $X" line over counter-offer chips); `TripEvaluator` applies the filters (pickup counts toward $/km and $/h; accept only if every enabled filter passes); `TripOverlay` draws a non-touchable TYPE_ACCESSIBILITY_OVERLAY card with a green/red border. Debug builds log every read (`adb logcat -s AnalisisViaje:D`) and keep the last 40 OCR inputs in the app's `cache/ocr/`. Unit tests: `android/app/src/test/`.
- **Dart ↔ service**: `lib/platform/trip_reader.dart` ↔ `MainActivity.kt` over `analisis_viaje/reader`. The service can't read Flutter's prefs, so Dart pushes filters + monitored packages (`TripReader.pushConfig`) on launch and after every change; `ReaderState.kt` stores them plus the `running` flag and session counters. Filter names (`FilterKind.name`) must stay identical in Dart and Kotlin. `lib/data/trip_filters.dart` only holds filter settings/slider ranges.
- **Persistence** (`lib/data/app_prefs.dart`): a thin wrapper over `shared_preferences`; filters are stored as `filter_<kind>_on` / `filter_<kind>_value`. Screens read prefs directly and write on change; there is no state-management package.
- **Localization**: all user-facing text lives in `lib/l10n/app_es.arb` (template) and `app_en.arb`; `flutter gen-l10n` (also run automatically on build) regenerates `lib/l10n/app_localizations*.dart`. Never hardcode UI strings: add a key to both ARB files and use `AppLocalizations.of(context)`. The app launches in Mexico only, so `MyApp` pins `locale: Locale('es')`; the user removed the language selector and the country/flag chip. English is kept in the ARB files so it can be re-enabled later. The brand name `AppInfo.name` is intentionally untranslated.
- **UI**: colors live in `AppColors` (`lib/theme/app_theme.dart`); reusable pieces (`PrimaryButton`, `AppCard`, `IconTile`, `StatusBanner`, `FeatureRow`) are in `lib/widgets/common.dart`. App name and logo path are in `lib/app_info.dart`.

## Testing notes

- Widget tests must call `SharedPreferences.setMockInitialValues(...)` and pass `await AppPrefs.load()` to `MyApp`, then `pumpAndSettle()` to get past the splash.
- Tab content is in `ListView`s, so off-screen widgets aren't built in the 800×600 test viewport; use `scrollUntilVisible` before asserting on them.
