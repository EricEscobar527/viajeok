package cloud.doublee.viajeok.reader

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo

/**
 * "Lectura de pantalla": reads the trip offer from DiDi/Uber while analysis
 * is running, and shows [TripOverlay] with the verdict. Uses the apps'
 * accessibility text when they expose it, and falls back to [ScreenOcr]
 * when an offer card is on screen without readable text (DiDi).
 */
class TripReaderService : AccessibilityService() {
    private lateinit var state: ReaderState
    private lateinit var overlay: TripOverlay
    private lateinit var ocr: ScreenOcr
    private val handler = Handler(Looper.getMainLooper())
    private var debug = false

    /** The offer the popup is showing, so each card is shown only once. */
    private var currentOffer: TripOffer? = null
    private var scanQueued = false
    private var polling = false

    private val scan = Runnable {
        scanQueued = false
        scanScreen()
    }

    // DiDi's offer card fires no accessibility events while it's shown, so
    // while a ride app is in front the screen is re-read on a timer too.
    private val poll = object : Runnable {
        override fun run() {
            if (!state.running || !rideAppInFront()) {
                polling = false
                offerGone()
                return
            }
            scanScreen()
            handler.postDelayed(this, POLL_MS)
        }
    }
    private var hidePending = false
    private val hide = Runnable {
        hidePending = false
        overlay.hide()
        currentOffer = null
    }

    // Stopping analysis from the app hides the popup right away.
    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if ((key == "running" || key == "lock_at") && !state.running) handler.post(hide)
    }

    override fun onServiceConnected() {
        instance = this
        state = ReaderState(this)
        overlay = TripOverlay(this)
        debug = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        ocr = ScreenOcr(this, debug)
        getSharedPreferences("trip_reader", Context.MODE_PRIVATE)
            .registerOnSharedPreferenceChangeListener(prefsListener)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (!state.running) return
        val pkg = event.packageName?.toString() ?: return
        if (debug) Log.v(TAG, "event ${AccessibilityEvent.eventTypeToString(event.eventType)} pkg=$pkg")
        if (pkg !in state.packages) return
        // Offer cards fire bursts of events; scan once per burst.
        queueScan(SCAN_DELAY_MS)
        if (!polling) {
            polling = true
            handler.postDelayed(poll, POLL_MS)
        }
    }

    /** Package of the app in front; kept when its window is hidden from us. */
    private var frontPackage: String? = null

    // While DiDi shows an offer its window can come back with no root (the
    // app hides it from accessibility services), so a missing root keeps the
    // last known front app instead of meaning "left the ride app".
    private fun rideAppInFront(): Boolean {
        val front = windows.firstOrNull { it.type == AccessibilityWindowInfo.TYPE_APPLICATION && it.isActive }
        val pkg = front?.root?.packageName?.toString()
        if (pkg != null) frontPackage = pkg
        if (debug) {
            Log.d(TAG, "front=${front?.title} root=$pkg kept=$frontPackage windows=" +
                windows.joinToString { "${it.type}:${it.title}:${it.root?.packageName}:${if (it.isActive) "A" else ""}" })
        }
        return frontPackage in state.packages
    }

    private fun scanScreen() {
        val texts = readTexts()
        val offer = TripParser.parse(texts)
        if (debug) {
            Log.d(TAG, "scan texts(${texts.size})=${texts.take(60).joinToString(" | ")}")
            Log.d(TAG, "offer=$offer")
        }

        // DiDi exposes no offer text at all, and its view tree gives no
        // reliable "offer showing" signal, so whenever a ride app is in
        // front and its text has no offer, the screenshot decides.
        if (offer != null) showOffer(offer) else scanWithOcr()
    }

    // Busy or rate-limited reads are simply skipped; the next poll retries.
    private fun scanWithOcr() {
        ocr.read(exclude = overlay.screenBounds()) { lines ->
            val offer = TripParser.parse(lines)
            if (debug) Log.d(TAG, "ocr lines(${lines.size})=${lines.joinToString(" | ")} offer=$offer")
            when {
                offer != null -> showOffer(offer)
                // Our popup can cover the fare on tall cards (Uber); the same
                // legs still on screen means it's the same offer.
                currentOffer?.legs == TripParser.legs(lines) && currentOffer != null ->
                    offerStillVisible()
                else -> offerGone()
            }
        }
    }

    private fun queueScan(delay: Long) {
        if (scanQueued) return
        scanQueued = true
        handler.postDelayed(scan, delay)
    }

    // Card gone (accepted, rejected or expired): hide shortly after the last
    // time it was seen. Later "gone" reads must not push the hide back, or
    // the popup would linger as long as polling keeps finding nothing.
    private fun offerGone() {
        if (overlay.isShowing && !hidePending) {
            hidePending = true
            handler.postDelayed(hide, HIDE_AFTER_GONE_MS)
        }
    }

    private fun offerStillVisible() {
        handler.removeCallbacks(hide)
        hidePending = false
    }

    private fun showOffer(offer: TripOffer) {
        if (!state.running) return
        offerStillVisible()
        // A misread fare on a later poll of the same card isn't a new offer.
        if (offer.legs != currentOffer?.legs) {
            currentOffer = offer
            val failed = TripEvaluator.failed(offer, state.filters)
            // Picked once per offer, so later polls of it keep the same text.
            overlay.show(offer, failed, frontPackage, state.labelFor(failed.isEmpty()))
        }
    }

    /**
     * Debug builds only: runs a saved screenshot through OCR → parser →
     * filters → popup. Lets Uber/DiDi cards be checked
     * on a real phone without a live offer (see DebugOfferActivity).
     */
    fun analyzeForDebug(bitmap: android.graphics.Bitmap, app: String, onResult: (String) -> Unit) {
        if (!debug) return
        ocr.recognize(bitmap) { lines ->
            val offer = TripParser.parse(lines)
            val failed = offer?.let { TripEvaluator.failed(it, state.filters) }
            Log.d(TAG, "debug-image lines(${lines.size})=${lines.joinToString(" | ")}")
            Log.d(TAG, "debug-image offer=$offer failed=$failed")
            if (offer != null) {
                overlay.show(offer, failed!!, app, state.labelFor(failed.isEmpty()))
            } else {
                overlay.hide()
            }
            onResult("offer=$offer failed=$failed")
        }
    }

    /** Removes the popup and switches this service off in Android settings. */
    @androidx.annotation.RequiresApi(android.os.Build.VERSION_CODES.N)
    fun turnOff() {
        handler.removeCallbacksAndMessages(null)
        overlay.hide()
        currentOffer = null
        disableSelf()
    }

    /** Debug builds only: the replayed screenshot left the screen. */
    fun hideDebugPopup() {
        if (debug) handler.post(hide)
    }


    /** Text and content descriptions from every window of a monitored app. */
    private fun readTexts(): List<String> {
        val roots = (windows.mapNotNull { it.root } + listOfNotNull(rootInActiveWindow))
            .filter { it.packageName?.toString() in state.packages }
            .distinct()
        val texts = mutableListOf<String>()
        fun walk(node: AccessibilityNodeInfo, depth: Int) {
            if (depth > MAX_DEPTH) return
            node.text?.toString()?.takeIf { it.isNotBlank() }?.let(texts::add)
            node.contentDescription?.toString()?.takeIf { it.isNotBlank() }?.let(texts::add)
            for (i in 0 until node.childCount) node.getChild(i)?.let { walk(it, depth + 1) }
        }
        for (root in roots) walk(root, 0)
        return texts
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        if (instance === this) instance = null
        handler.removeCallbacksAndMessages(null)
        if (::overlay.isInitialized) overlay.hide()
        if (::ocr.isInitialized) ocr.close()
        if (::state.isInitialized) {
            getSharedPreferences("trip_reader", Context.MODE_PRIVATE)
                .unregisterOnSharedPreferenceChangeListener(prefsListener)
        }
        super.onDestroy()
    }

    companion object {
        private const val TAG = "ViajeOK"
        private const val SCAN_DELAY_MS = 250L
        private const val HIDE_AFTER_GONE_MS = 2500L
        private const val MAX_DEPTH = 40
        private const val POLL_MS = 1200L

        /** The running service, for the debug-only image check. */
        var instance: TripReaderService? = null
            private set

        fun isEnabled(context: Context): Boolean {
            val me = ComponentName(context, TripReaderService::class.java).flattenToString()
            val enabled = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ) ?: return false
            return enabled.split(':').any { it.equals(me, ignoreCase = true) }
        }
    }
}
