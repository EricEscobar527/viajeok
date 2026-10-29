package cloud.doublee.viajeok.reader

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.TextUtils
import android.text.style.ForegroundColorSpan
import android.util.TypedValue
import android.view.Gravity
import android.view.View
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
     * screen has nothing to tap or read. [caption] is one of the user's own
     * texts for this verdict (Configuración), shown on top; null = none.
     *
     * Look: a solid verdict band (✓/✕) on the left of a flat, slightly
     * rounded card, text left-aligned; ViajeOK's own style rather than a
     * fully outlined pill.
     */
    fun show(offer: TripOffer, failed: List<FilterKind>, app: String?, caption: String? = null) {
        hide()
        val accept = failed.isEmpty()
        val color = if (accept) GREEN else RED
        val radius = dp(CORNER_DP).toFloat()

        val band = TextView(context).apply {
            text = if (accept) "✓" else "✕"
            setTextColor(BACKGROUND)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            minWidth = dp(34)
            background = GradientDrawable().apply {
                setColor(color)
                cornerRadii = floatArrayOf(radius, radius, 0f, 0f, 0f, 0f, radius, radius)
            }
        }
        val detailView = text(detail(offer, failed, short = false), DETAIL_SP, SECONDARY)
        val body = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(12), dp(7), dp(14), dp(7))
            if (caption != null) {
                addView(
                    text(caption, 12f, LABEL, bold = true).apply {
                        // One line, cut with "…" so a long text never grows the card.
                        maxLines = 1
                        ellipsize = TextUtils.TruncateAt.END
                        maxWidth = dp(LABEL_MAX_DP)
                    },
                )
            }
            // Kept short: it sits at the very top so it doesn't cover the
            // ride app's card, which on Uber can start near the top.
            addView(text("${money(offer.perKm)}/km  ·  ${money(offer.perHour)}/h", 18f, color, bold = true))
            addView(detailView)
        }
        val view = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            background = GradientDrawable().apply {
                setColor(BACKGROUND)
                cornerRadius = radius
                setStroke(dp(1), BORDER)
            }
            addView(band, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.MATCH_PARENT))
            addView(body)
        }

        // A WRAP_CONTENT window is first measured narrower than the screen
        // and wraps the fare line onto a 4th line, so the width is set from
        // the card's natural size. If several failed minimums don't fit the
        // screen even so, their short names are used, then a smaller font.
        val maxWidth = context.resources.displayMetrics.widthPixels - dp(16)
        val unspecified = View.MeasureSpec.UNSPECIFIED
        view.measure(unspecified, unspecified)
        if (view.measuredWidth > maxWidth && !accept) {
            detailView.text = detail(offer, failed, short = true)
            view.measure(unspecified, unspecified)
            var sp = DETAIL_SP
            while (view.measuredWidth > maxWidth && sp > DETAIL_MIN_SP) {
                sp -= 0.5f
                detailView.setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
                view.measure(unspecified, unspecified)
            }
        }

        val params = WindowManager.LayoutParams(
            minOf(view.measuredWidth, maxWidth),
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

    private fun text(value: CharSequence, sp: Float, color: Int, bold: Boolean = false) =
        TextView(context).apply {
            text = value
            setTextColor(color)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
            if (bold) typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.START
            // Drops the extra space Android adds above/below each line: the
            // popup must fit between DiDi's button and its card.
            includeFontPadding = false
            setLineSpacing(dp(1).toFloat(), 1f)
        }

    // Failed minimums go on the same line as the fare, in red, so a red
    // popup is no taller than a green one: DiDi cards with an extra row
    // start just below it. Non-breaking spaces keep each name in one piece.
    private fun detail(offer: TripOffer, failed: List<FilterKind>, short: Boolean): CharSequence {
        val detail = SpannableStringBuilder(
            "${money(offer.fare)} · ${num(offer.totalKm)} km · ${offer.totalMinutes.toInt()} min",
        )
        if (failed.isNotEmpty()) {
            val start = detail.length
            detail.append(failed.joinToString(prefix = "   ", separator = "  ") { "✕ ${label(it, short)}".replace(' ', ' ') })
            detail.setSpan(ForegroundColorSpan(RED), start, detail.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        return detail
    }

    private fun label(kind: FilterKind, short: Boolean) = when (kind) {
        FilterKind.perHour -> if (short) "$/h" else "Por hora"
        FilterKind.perKm -> if (short) "$/km" else "Por km"
        FilterKind.maxPickupKm -> if (short) "Pickup" else "Pickup máx."
    }

    private fun money(v: Double) = "$" + String.format(Locale.US, "%.2f", v)
    private fun num(v: Double) = String.format(Locale.US, "%.1f", v)
    // DiDi has a "Rechazo permitido" button at the top right and its card
    // starts around 20–40% down (20% with an extra "Al precio de Express" row),
    // so the popup sits in the map between them, kept to 3 lines.
    // Uber's offer cards start around half the screen; right under the
    // status bar looked too high, so it sits a bit lower (never above the
    // status bar on short screens).
    private fun topFor(app: String?): Int {
        val height = context.resources.displayMetrics.heightPixels
        return when (app) {
            ReaderState.DIDI_DRIVER -> (height * DIDI_TOP).toInt()
            else -> maxOf((height * UBER_TOP).toInt(), statusBarHeight() + dp(2))
        }
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
        /** The user's label: light gray, softer than plain white. */
        val LABEL = Color.parseColor("#C9CED6")
        val BORDER = Color.parseColor("#434A53")

        const val CORNER_DP = 6

        /** Fare line size, and how far it may shrink to stay on one line. */
        const val DETAIL_SP = 12.5f
        const val DETAIL_MIN_SP = 10.5f

        /** Label width cap; the Dart input also limits it to 30 characters. */
        const val LABEL_MAX_DP = 250

        /** Fraction of the screen height where the popup starts on DiDi. */
        const val DIDI_TOP = 0.12

        /** Same, on Uber Driver. */
        const val UBER_TOP = 0.10
    }
}
