package cloud.doublee.viajeok

import android.content.Intent
import android.os.Build
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
                    // Attached to support reports (lib/platform/device_info.dart).
                    "deviceInfo" -> result.success(deviceInfo())
                    else -> result.notImplemented()
                }
            }
    }

    private fun openServiceSettings() {
        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
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
