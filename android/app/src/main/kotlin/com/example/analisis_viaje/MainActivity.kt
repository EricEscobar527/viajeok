package com.example.analisis_viaje

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.example.analisis_viaje.reader.ReaderState
import com.example.analisis_viaje.reader.TripReaderService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "analisis_viaje/permissions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canDrawOverlays" -> result.success(canDrawOverlays())
                    "openOverlaySettings" -> {
                        startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName"),
                            )
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Bridge to TripReaderService (lib/platform/trip_reader.dart).
        val reader = ReaderState(this)
        MethodChannel(messenger, "analisis_viaje/reader")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isServiceEnabled" -> result.success(TripReaderService.isEnabled(this))
                    "openServiceSettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "setConfig" -> {
                        reader.setConfig(call.arguments as Map<*, *>)
                        result.success(null)
                    }
                    "isRunning" -> result.success(reader.running)
                    "setRunning" -> {
                        val run = call.arguments as Boolean
                        if (run && !reader.running) reader.resetStats()
                        reader.running = run
                        result.success(null)
                    }
                    "getStats" -> result.success(reader.stats())
                    else -> result.notImplemented()
                }
            }
    }

    private fun canDrawOverlays(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
}
