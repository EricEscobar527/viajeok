package com.example.analisis_viaje.reader

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
 * "Lectura de pantalla": reads the trip offer from Uber/DiDi while analysis
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

    /** Identifies the offer on screen so one offer is counted only once. */
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
    private val hide = Runnable {
        overlay.hide()
        currentOffer = null
    }

    // Stopping analysis from the app hides the popup right away.
    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == "running" && !state.running) handler.post(hide)
    }

    override fun onServiceConnected() {
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
            if (offer != null) showOffer(offer) else offerGone()
        }
    }

    private fun queueScan(delay: Long) {
        if (scanQueued) return
        scanQueued = true
        handler.postDelayed(scan, delay)
    }

    // Card gone (accepted, rejected or expired): hide shortly after.
    private fun offerGone() {
        if (overlay.isShowing) {
            handler.removeCallbacks(hide)
            handler.postDelayed(hide, HIDE_AFTER_GONE_MS)
        }
    }

    private fun showOffer(offer: TripOffer) {
        if (!state.running) return
        handler.removeCallbacks(hide)
        if (offer != currentOffer) {
            currentOffer = offer
            val failed = TripEvaluator.failed(offer, state.filters)
            state.count(accepted = failed.isEmpty())
            overlay.show(offer, failed)
        }
        handler.postDelayed(hide, MAX_SHOW_MS)
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
        private const val TAG = "AnalisisViaje"
        private const val SCAN_DELAY_MS = 250L
        private const val HIDE_AFTER_GONE_MS = 1500L
        private const val MAX_SHOW_MS = 30_000L
        private const val MAX_DEPTH = 40
        private const val POLL_MS = 1200L


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
