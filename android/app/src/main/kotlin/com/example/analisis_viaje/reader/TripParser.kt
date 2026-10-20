package com.example.analisis_viaje.reader

/** A trip offer as read from the ride app's screen. */
data class TripOffer(
    val fare: Double,
    val pickupMinutes: Double,
    val pickupKm: Double,
    val tripMinutes: Double,
    val tripKm: Double,
) {
    // The driver isn't paid for driving to the passenger, so pickup counts too.
    val totalKm get() = pickupKm + tripKm
    val totalMinutes get() = pickupMinutes + tripMinutes
    val perKm get() = if (totalKm > 0) fare / totalKm else 0.0
    val perHour get() = if (totalMinutes > 0) fare / (totalMinutes / 60) else 0.0
}

/**
 * Extracts an offer from the visible texts of an Uber/DiDi offer card, e.g.
 * "$46.04", "8 min (1.8 km)", "24 min (8.7 km)", "Aceptar $46.04".
 * The first "time (distance)" leg is the pickup, the second is the trip.
 */
object TripParser {
    // "1 h 5 min (12.3 km)", "8 min (1.8 km)", "3 min (800 m)"
    private val leg = Regex(
        """(?:(\d+)\s*h\s*)?(\d+)\s*min\w*\s*\(\s*(\d+(?:[.,]\d+)?)\s*(km|m)\s*\)""",
        RegexOption.IGNORE_CASE,
    )

    // "$46.04", "MX$ 1,046.50", "$ 78"
    private val money = Regex("""\$\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)""")
    private val acceptButton = Regex("""aceptar|accept""", RegexOption.IGNORE_CASE)

    fun parse(texts: List<String>): TripOffer? {
        val all = texts.joinToString("\n")

        val legs = leg.findAll(all).map { m ->
            val minutes = (m.groupValues[1].toIntOrNull() ?: 0) * 60.0 + m.groupValues[2].toDouble()
            val dist = m.groupValues[3].replace(',', '.').toDouble()
            val km = if (m.groupValues[4].equals("m", ignoreCase = true)) dist / 1000 else dist
            minutes to km
        }.toList()
        if (legs.size < 2) return null

        val fare = fareFrom(texts) ?: return null
        val (pickupMin, pickupKm) = legs[0]
        val (tripMin, tripKm) = legs[1]
        return TripOffer(fare, pickupMin, pickupKm, tripMin, tripKm)
    }

    // The accept button repeats the real fare ("Aceptar $46.04"), unlike the
    // counter-offer chips next to it, so prefer it; else the first amount.
    private fun fareFrom(texts: List<String>): Double? {
        val fromButton = texts.firstOrNull { acceptButton.containsMatchIn(it) && money.containsMatchIn(it) }
        val source = fromButton ?: texts.firstOrNull { money.containsMatchIn(it) } ?: return null
        return money.find(source)?.groupValues?.get(1)?.replace(",", "")?.toDoubleOrNull()
    }
}
