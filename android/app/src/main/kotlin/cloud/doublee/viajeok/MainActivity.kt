package cloud.doublee.viajeok

import android.app.ActivityManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import cloud.doublee.viajeok.reader.ReaderState
import cloud.doublee.viajeok.reader.TripReaderService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Bridge to TripReaderService (lib/platform/trip_reader.dart).
        val reader = ReaderState(this)
        MethodChannel(messenger, "viajeok/reader")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isServiceEnabled" -> result.success(TripReaderService.isEnabled(this))
                    "openServiceSettings" -> {
                        openServiceSettings()
                        result.success(null)
                    }
                    "setConfig" -> {
                        reader.setConfig(call.arguments as Map<*, *>)
                        result.success(null)
                    }
                    // Banking apps (e.g. Nu) refuse to open while an accessibility
                    // service is on, so users need a one-tap way to turn it off.
                    // true = turned off directly; false = Settings was opened.
                    "disableService" -> {
                        reader.running = false
                        val service = TripReaderService.instance
                        if (service != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            service.turnOff()
                            result.success(true)
                        } else {
                            openServiceSettings()
                            result.success(false)
                        }
                    }
                    "isRunning" -> result.success(reader.running)
                    "setRunning" -> {
                        reader.running = call.arguments as Boolean
                        result.success(null)
                    }
                    "setLockAt" -> {
                        reader.lockAt = (call.arguments as Number).toLong()
                        result.success(null)
                    }
                    "openUrl" -> result.success(openUrl(call.arguments as String))
                    // Battery / autostart live on the app's own settings page.
                    "openAppSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                .setData(Uri.fromParts("package", packageName, null)),
                        )
                        result.success(null)
                    }
                    // Attached to support reports (lib/platform/device_info.dart).
                    "deviceInfo" -> result.success(deviceInfo())
                    // State of the reader, also attached to support reports.
                    "diagnostics" -> result.success(diagnostics(reader))
                    else -> result.notImplemented()
                }
            }
    }

    private fun openServiceSettings() {
        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }

    /** false when no app can open [url] (e.g. market:// without Play). */
    private fun openUrl(url: String): Boolean = try {
        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }

    /**
     * Why an alert might not show, for support: whether the accessibility
     * service is on and running, battery restrictions, which ride apps are
     * installed, and when the service last saw one in front or read an
     * offer. Nothing about the offers themselves.
     */
    private fun diagnostics(reader: ReaderState): Map<String, Any?> {
        val power = getSystemService(POWER_SERVICE) as PowerManager
        val activity = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        fun version(pkg: String): String? = try {
            packageManager.getPackageInfo(pkg, 0).versionName ?: "?"
        } catch (_: PackageManager.NameNotFoundException) {
            null
        }
        return mapOf(
            "serviceEnabled" to TripReaderService.isEnabled(this),
            "serviceConnected" to (TripReaderService.instance != null),
            "running" to reader.running,
            "locked" to reader.locked,
            "batteryUnrestricted" to power.isIgnoringBatteryOptimizations(packageName),
            "backgroundRestricted" to activity.isBackgroundRestricted,
            "powerSave" to power.isPowerSaveMode,
            "didi" to version(ReaderState.DIDI_DRIVER),
            "uber" to version(ReaderState.UBER_DRIVER),
            "rappi" to version(ReaderState.RAPPI_COURIER),
            "lastRideApp" to reader.lastRideApp,
            "lastRideAppAt" to reader.lastRideAppAt,
            "lastOfferAt" to reader.lastOfferAt,
        )
    }

    private fun deviceInfo(): Map<String, Any?> {
        val pkg = packageManager.getPackageInfo(packageName, 0)
        @Suppress("DEPRECATION")
        val build = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pkg.longVersionCode else pkg.versionCode.toLong()
        return mapOf(
            "appVersion" to pkg.versionName,
            "appBuild" to build,
            "androidVersion" to Build.VERSION.RELEASE,
            "androidSdk" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
        )
    }
}
