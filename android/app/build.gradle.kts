import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key for Play. android/key.properties and the keystore live outside
// git (see .gitignore); without them release builds fall back to the debug
// key, which is fine locally but must never be uploaded to Play.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasUploadKey = keyProperties.getProperty("storeFile") != null

android {
    namespace = "cloud.doublee.viajeok"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once published on Play.
        applicationId = "cloud.doublee.viajeok"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 11+: reading offers needs the accessibility screenshot
        // (API 30) for DiDi and Rappi, so older phones could install the app
        // but never get an alert (support ticket SOP-000013, Android 10).
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "ViajeOK"
        // Meta SDK (install attribution for Meta ads): on only in release.
        manifestPlaceholders["metaSdkEnabled"] = "true"
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        // Debug installs next to the Play Store build (different package), so
        // diagnostics never require uninstalling the real app.
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appLabel"] = "ViajeOK Debug"
            // The .debug package isn't the app registered in Meta: send nothing.
            manifestPlaceholders["metaSdkEnabled"] = "false"
        }
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("upload")
            } else {
                logger.warn("android/key.properties not found: release is signed with the DEBUG key. Don't upload it to Play.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

// A release without Meta's client token would crash the SDK's auto-init.
gradle.taskGraph.whenReady {
    val releasing = allTasks.any { it.project == project && it.name.contains("Release") }
    val metaStrings = file("src/main/res/values/meta_sdk.xml")
    if (releasing && metaStrings.readText().contains("PENDING_CLIENT_TOKEN")) {
        throw GradleException("Set facebook_client_token in ${metaStrings.path} before building a release.")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // On-device OCR for offer cards without accessibility text (DiDi).
    implementation("com.google.mlkit:text-recognition:16.0.1")
    // Meta SDK, app events only: logs installs/app opens so Meta ads can
    // optimize for installs. Configured in AndroidManifest.xml.
    implementation("com.facebook.android:facebook-core:18.3.0")
    testImplementation("junit:junit:4.13.2")
}
