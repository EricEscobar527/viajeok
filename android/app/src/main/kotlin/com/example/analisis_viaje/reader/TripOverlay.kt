package com.example.analisis_viaje.reader

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import java.util.Locale

/**
 * The green/red card drawn over DiDi/Uber. Uses TYPE_ACCESSIBILITY_OVERLAY,
 * so it needs no extra permission, and is not touchable so taps go through
 * to the ride app underneath.
 */
class TripOverlay(private val context: Context) {
    private val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var card: LinearLayout? = null

    val isShowing get() = card != null

    /** Where the popup is on screen, so OCR can skip reading it back. */
    fun screenBounds(): Rect? = card?.let {
        val xy = IntArray(2).also { a -> it.getLocationOnScreen(a) }
        Rect(xy[0], xy[1], xy[0] + it.width, xy[1] + it.height)
    }

    /**
     * [app] is the ride app's package; the popup goes where that app's
     * screen has nothing to tap or read.
     */
    fun show(offer: TripOffer, failed: List<FilterKind>, app: String?) {
        hide()
        val accept = failed.isEmpty()
        val color = if (accept) GREEN else RED

        val view = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(16), dp(6), dp(16), dp(8))
            background = GradientDrawable().apply {
                setColor(BACKGROUND)
                cornerRadius = dp(14).toFloat()
                setStroke(dp(3), color)
            }
            // Kept short: it sits at the very top so it doesn't cover the
            // ride app's card, which on Uber can start near the top.
            addView(text("${money(offer.perKm)}/km  ·  ${money(offer.perHour)}/h", 20f, color, bold = true))
            addView(
                text(
                    "${money(offer.fare)} · ${num(offer.totalKm)} km · ${offer.totalMinutes.toInt()} min",
                    13f,
                    SECONDARY,
                ),
            )
            if (!accept) {
                addView(text(failed.joinToString("  ") { "✕ ${label(it)}" }, 13f, RED))
            }
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = topFor(app)
        }
        wm.addView(view, params)
        card = view
    }

    fun hide() {
        card?.let { runCatching { wm.removeView(it) } }
        card = null
    }

    private fun text(value: String, sp: Float, color: Int, bold: Boolean = false) =
        TextView(context).apply {
            text = value
            setTextColor(color)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
            if (bold) typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }

    private fun label(kind: FilterKind) = when (kind) {
        FilterKind.perHour -> "Por hora"
        FilterKind.perKm -> "Por km"
        FilterKind.maxPickupKm -> "Pickup máx."
    }

    private fun money(v: Double) = "$" + String.format(Locale.US, "%.2f", v)
    private fun num(v: Double) = String.format(Locale.US, "%.1f", v)
    // DiDi has a "Rechazo permitido" button at the top right and its card
    // starts around 27–40% down, so the popup sits in the map between them.
    // Uber's card can start right below the status bar (tall UberX cards),
    // so there the popup hugs the status bar to keep the fare visible.
    private fun topFor(app: String?): Int = when (app) {
        ReaderState.DIDI_DRIVER -> (context.resources.displayMetrics.heightPixels * DIDI_TOP).toInt()
        else -> statusBarHeight() + dp(2)
    }

    private fun statusBarHeight(): Int {
        val id = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (id > 0) context.resources.getDimensionPixelSize(id) else dp(28)
    }

    private fun dp(v: Int) = (v * context.resources.displayMetrics.density).toInt()

    private companion object {
        // Same values as AppColors in lib/theme/app_theme.dart.
        val BACKGROUND = Color.parseColor("#1F2329")
        val GREEN = Color.parseColor("#34D399")
        val RED = Color.parseColor("#F87171")
        val SECONDARY = Color.parseColor("#B4BAC2")

        /** Fraction of the screen height where the popup starts on DiDi. */
        const val DIDI_TOP = 0.12
    }
}
