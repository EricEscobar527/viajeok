package com.example.analisis_viaje.reader

import android.accessibilityservice.AccessibilityService
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.Build
import android.util.Log
import android.view.Display
import androidx.annotation.RequiresApi
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

/**
 * Reads text from a screenshot, for ride apps that draw the offer card
 * without accessibility text (DiDi renders it with Flutter). Uses the
 * accessibility screenshot API, so there's no screen-share prompt, and
 * on-device ML Kit OCR, so nothing leaves the phone.
 */
class ScreenOcr(private val service: AccessibilityService, private val debug: Boolean) {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    private var busy = false
    private var lastShotAt = 0L

    val isSupported get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

    /**
     * Calls [onLines] with the recognized lines, top to bottom, or with an
     * empty list on failure. Returns false (and does nothing) if a capture
     * is already in flight or Android's ~1/s screenshot limit would hit.
     * Lines overlapping [exclude] (screen coordinates; our own popup) are
     * dropped.
     */
    fun read(exclude: Rect? = null, onLines: (List<String>) -> Unit): Boolean {
        if (!isSupported || busy) return false
        if (System.currentTimeMillis() - lastShotAt < MIN_INTERVAL_MS) return false
        busy = true
        lastShotAt = System.currentTimeMillis()
        capture { bitmap ->
            if (bitmap == null) {
                busy = false
                onLines(emptyList())
                return@capture
            }
            if (debug) saveForDebug(bitmap)
            val skip = exclude?.let { toImage(it, bitmap) }
            recognizer.process(InputImage.fromBitmap(bitmap, 0))
                .addOnSuccessListener { result ->
                    onLines(
                        result.textBlocks.flatMap { it.lines }
                            .filter { line -> skip == null || line.boundingBox?.let { Rect.intersects(it, skip) } != true }
                            .sortedBy { it.boundingBox?.top ?: 0 }
                            .map { it.text },
                    )
                }
                .addOnFailureListener {
                    Log.w(TAG, "ocr failed", it)
                    onLines(emptyList())
                }
                .addOnCompleteListener {
                    bitmap.recycle()
                    busy = false
                }
        }
        return true
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun capture(onBitmap: (Bitmap?) -> Unit) {
        service.takeScreenshot(
            Display.DEFAULT_DISPLAY,
            service.mainExecutor,
            object : AccessibilityService.TakeScreenshotCallback {
                override fun onSuccess(shot: AccessibilityService.ScreenshotResult) {
                    val hw = Bitmap.wrapHardwareBuffer(shot.hardwareBuffer, shot.colorSpace)
                    shot.hardwareBuffer.close()
                    if (hw == null) return onBitmap(null)
                    // Skip the top of the screen: the offer card sits lower,
                    // and our own popup lives up there.
                    val top = (hw.height * CROP_TOP).toInt()
                    cropTopPx = top
                    val soft = hw.copy(Bitmap.Config.ARGB_8888, false)
                    hw.recycle()
                    // Half resolution is plenty for the card's large text
                    // and keeps OCR cheap enough to run every poll.
                    val cropped = Bitmap.createBitmap(soft, 0, top, soft.width, soft.height - top)
                    val small = Bitmap.createScaledBitmap(cropped, cropped.width / SCALE, cropped.height / SCALE, true)
                    if (cropped !== soft) cropped.recycle()
                    soft.recycle()
                    onBitmap(small)
                }

                override fun onFailure(errorCode: Int) {
                    Log.w(TAG, "screenshot failed: $errorCode")
                    onBitmap(null)
                }
            },
        )
    }

    // Screen coordinates → the cropped, half-size image's coordinates.
    private var cropTopPx = 0

    private fun toImage(r: Rect, bitmap: Bitmap) =
        Rect(r.left / SCALE, (r.top - cropTopPx) / SCALE, r.right / SCALE, (r.bottom - cropTopPx) / SCALE)
            .takeIf { it.bottom > 0 && it.top < bitmap.height }

    // Debug builds keep the last few OCR inputs in cache/ocr/ to inspect with
    // `adb shell run-as com.example.analisis_viaje ls cache/ocr`.
    private fun saveForDebug(bitmap: Bitmap) {
        runCatching {
            val dir = java.io.File(service.cacheDir, "ocr").apply { mkdirs() }
            dir.listFiles()?.sortedBy { it.name }?.dropLast(KEEP_DEBUG_SHOTS)?.forEach { it.delete() }
            val name = java.text.SimpleDateFormat("HHmmss_SSS", java.util.Locale.US).format(java.util.Date())
            java.io.File(dir, "$name.jpg").outputStream().use {
                bitmap.compress(Bitmap.CompressFormat.JPEG, 60, it)
            }
        }
    }

    fun close() = recognizer.close()

    private companion object {
        const val TAG = "AnalisisViaje"
        const val MIN_INTERVAL_MS = 1000L
        const val CROP_TOP = 0.2
        const val SCALE = 2
        const val KEEP_DEBUG_SHOTS = 40
    }
}
