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
 * The green/red card drawn over Uber/DiDi. Uses TYPE_ACCESSIBILITY_OVERLAY,
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

    fun show(offer: TripOffer, failed: List<FilterKind>) {
        hide()
        val accept = failed.isEmpty()
        val color = if (accept) GREEN else RED

        val view = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(18), dp(12), dp(18), dp(12))
            background = GradientDrawable().apply {
                setColor(BACKGROUND)
                cornerRadius = dp(18).toFloat()
                setStroke(dp(4), color)
            }
            addView(text("${money(offer.perKm)}/km", 26f, color, bold = true))
            addView(text("${money(offer.perHour)}/h", 16f, Color.WHITE, bold = true))
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
            y = dp(96)
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
    private fun dp(v: Int) = (v * context.resources.displayMetrics.density).toInt()

    private companion object {
        // Same values as AppColors in lib/theme/app_theme.dart.
        val BACKGROUND = Color.parseColor("#121212")
        val GREEN = Color.parseColor("#2ECC71")
        val RED = Color.parseColor("#EF4444")
        val SECONDARY = Color.parseColor("#9EA3AA")
    }
}
