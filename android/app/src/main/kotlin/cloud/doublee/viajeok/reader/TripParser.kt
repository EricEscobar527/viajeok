package cloud.doublee.viajeok.reader

/**
 * A trip offer as read from the DiDi/Uber screen. Uber deliveries only give
 * a combined "Total" leg, so [hasPickup] is false there and the pickup
 * fields are 0.
 */
data class TripOffer(
    val fare: Double,
    val pickupMinutes: Double,
    val pickupKm: Double,
    val tripMinutes: Double,
    val tripKm: Double,
    val hasPickup: Boolean = true,
) {
    // The driver isn't paid for driving to the passenger, so pickup counts too.
    val totalKm get() = pickupKm + tripKm
    val totalMinutes get() = pickupMinutes + tripMinutes
    val perKm get() = if (totalKm > 0) fare / totalKm else 0.0
    val perHour get() = if (totalMinutes > 0) fare / (totalMinutes / 60) else 0.0

    val legs get() = TripLegs(pickupMinutes, pickupKm, tripMinutes, tripKm, hasPickup)
}

/** The time/distance part of an offer, readable even when the fare isn't. */
data class TripLegs(
    val pickupMinutes: Double,
    val pickupKm: Double,
    val tripMinutes: Double,
    val tripKm: Double,
    val hasPickup: Boolean,
)

/**
 * Extracts an offer from the visible texts of an offer card. Formats seen:
 *
 * - DiDi: "$46.04", "8 min (1.8 km)", "24 min (8.7 km)", "Aceptar $46.04",
 *   counter-offer chips "$47.04", "$2.46 de tarifa base dinámica".
 * - Uber rides: "$152.75" or "MXN209.86", "A 8 min (3.8 km)",
 *   "Viaje: 1 h 25 min (32.8 km)", "$14.83/km (estimado)", "+$8.00 incluido".
 * - Uber deliveries: "MXN44", "Total: 26 min (11.4 km)", "Puede incluir propinas".
 *
 * Two legs mean pickup then trip; a single "Total" leg covers everything.
 */
object TripParser {
    // "1 h 5 min (12.3 km)", "8 min (1.8 km)", "3 min (800 m)"
    private val leg = Regex(
        """(?:(\d+)\s*h\s*)?(\d+)\s*min\w*\s*\(\s*(\d+(?:[.,]\d+)?)\s*(km|m)\s*\)""",
        RegexOption.IGNORE_CASE,
    )

    // "$46.04", "MXN209.86", "MXN 44", "MX$1,046.50". A currency marker is
    // required so ratings, counts and street numbers are never taken as fares.
    private val money = Regex(
        """(?:MXN\s*\$?|MX\$|\$)\s?(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)""",
        RegexOption.IGNORE_CASE,
    )
    private val acceptButton = Regex("""aceptar|accept""", RegexOption.IGNORE_CASE)
    private val total = Regex("""total""", RegexOption.IGNORE_CASE)

    // Amounts that are not the fare: rates, bonuses already included, tips.
    private val notFareLine = Regex(
        """incluid|propina|tarifa base|din[aá]mica|estimad""",
        RegexOption.IGNORE_CASE,
    )
    private val rateSuffix = Regex("""^\s*/\s*(km|h|hr|min)""", RegexOption.IGNORE_CASE)

    // OCR reads digits as look-alike letters: "lh 44 min" (1 h), "O9 min",
    // "1O min". Inside number tokens (and an hour count right before "h"),
    // map O/o → 0 and l/I/| → 1. Tokens without any digit are left alone,
    // so words aren't touched.
    private val numberToken = Regex(
        """(?<![A-Za-zÀ-ÿ])(?=[0-9OolI|.,]*\d)[0-9OolI|][0-9OolI|.,]*(?![A-Za-zÀ-ÿ])""",
    )
    private val hourDigit = Regex("""(?<![A-Za-zÀ-ÿ0-9])[lI|](?=\s*h\s*\d)""")

    internal fun ocrDigits(line: String): String =
        numberToken.replace(hourDigit.replace(line, "1")) { m ->
            m.value.replace('O', '0').replace('o', '0').replace('l', '1').replace('I', '1').replace('|', '1')
        }

    fun parse(texts: List<String>): TripOffer? {
        val clean = texts.map(::ocrDigits)
        val legs = legs(clean) ?: return null
        val fare = fare(clean) ?: return null
        return TripOffer(fare, legs.pickupMinutes, legs.pickupKm, legs.tripMinutes, legs.tripKm, legs.hasPickup)
    }

    fun legs(texts: List<String>): TripLegs? {
        class Leg(val minutes: Double, val km: Double, val isTotal: Boolean)

        val found = texts.map(::ocrDigits).flatMap { line ->
            leg.findAll(line).map { m ->
                val minutes = (m.groupValues[1].toIntOrNull() ?: 0) * 60.0 + m.groupValues[2].toDouble()
                val dist = m.groupValues[3].replace(',', '.').toDouble()
                val km = if (m.groupValues[4].equals("m", ignoreCase = true)) dist / 1000 else dist
                Leg(minutes, km, total.containsMatchIn(line.substring(0, m.range.first)))
            }.toList()
        }

        val parts = found.filter { !it.isTotal }
        if (parts.size >= 2) {
            return TripLegs(parts[0].minutes, parts[0].km, parts[1].minutes, parts[1].km, hasPickup = true)
        }
        val all = found.firstOrNull { it.isTotal } ?: return null
        return TripLegs(0.0, 0.0, all.minutes, all.km, hasPickup = false)
    }

    // DiDi's accept button repeats the real fare ("Aceptar $46.04"), unlike
    // the counter-offer chips next to it, so it wins. Otherwise the first
    // amount that isn't a rate, an included bonus or a tip.
    private fun fare(texts: List<String>): Double? {
        texts.firstOrNull { acceptButton.containsMatchIn(it) }
            ?.let { money.find(it) }
            ?.let { return amount(it) }

        for (line in texts) {
            if (notFareLine.containsMatchIn(line)) continue
            for (m in money.findAll(line)) {
                val before = line.substring(0, m.range.first).trimEnd()
                val after = line.substring(m.range.last + 1)
                if (before.endsWith("+") || rateSuffix.containsMatchIn(after)) continue
                return amount(m)
            }
        }
        return null
    }

    private fun amount(m: MatchResult) = m.groupValues[1].replace(",", "").toDoubleOrNull()
}
