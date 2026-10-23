package cloud.doublee.viajeok

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.widget.ImageView
import cloud.doublee.viajeok.reader.ReaderState
import cloud.doublee.viajeok.reader.TripReaderService
import java.io.File

/**
 * Debug builds only. Shows a saved offer screenshot full screen and runs it
 * through the real OCR → parser → filters → popup pipeline, so ride-app
 * offer cards can be checked on a phone without a live offer:
 *
 *   adb push card.jpg /data/local/tmp/card.jpg
 *   adb shell run-as cloud.doublee.viajeok cp /data/local/tmp/card.jpg files/card.jpg
 *   adb shell am start -n cloud.doublee.viajeok/.DebugOfferActivity --es image card.jpg --es app didi
 *
 * `app` (didi | uber, default uber) picks where the popup is placed.
 * The result is logged under the ViajeOK tag. Needs the accessibility
 * service enabled (the popup is drawn by it).
 */
class DebugOfferActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        show(intent)
    }

    // Launching again with another image reuses this activity.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        show(intent)
    }

    // Like a real card disappearing: the popup goes with the image.
    override fun onStop() {
        super.onStop()
        TripReaderService.instance?.hideDebugPopup()
    }

    private fun show(intent: Intent) {
        val name = intent.getStringExtra("image") ?: return finish()
        val bitmap = BitmapFactory.decodeFile(File(filesDir, name).path)
        if (bitmap == null) {
            Log.w(TAG, "debug-image: can't read files/$name")
            return finish()
        }
        setContentView(
            ImageView(this).apply {
                setBackgroundColor(Color.BLACK)
                scaleType = ImageView.ScaleType.FIT_CENTER
                setImageBitmap(bitmap)
            },
        )
        val service = TripReaderService.instance
        if (service == null) {
            Log.w(TAG, "debug-image: accessibility service not running")
            return
        }
        Log.d(TAG, "debug-image: analyzing $name (${bitmap.width}x${bitmap.height})")
        val app = if (intent.getStringExtra("app") == "didi") ReaderState.DIDI_DRIVER else ReaderState.UBER_DRIVER
        service.analyzeForDebug(bitmap, app) { Log.d(TAG, "debug-image result $name: $it") }
    }

    private companion object {
        const val TAG = "ViajeOK"
    }
}
