package com.example.analisis_viaje.reader

/** Mirrors FilterKind in lib/data/trip_filters.dart (same names). */
enum class FilterKind(val isMaximum: Boolean) {
    perHour(false),
    perKm(false),
    maxPickupKm(true);

    fun measure(t: TripOffer): Double = when (this) {
        perHour -> t.perHour
        perKm -> t.perKm
        maxPickupKm -> t.pickupKm
    }
}

data class TripFilter(val kind: FilterKind, val enabled: Boolean, val value: Double) {
    fun passes(t: TripOffer): Boolean {
        val v = kind.measure(t)
        return if (kind.isMaximum) v <= value else v >= value
    }
}

object TripEvaluator {
    /** Enabled filters the trip fails. Empty means accept (green). */
    fun failed(trip: TripOffer, filters: List<TripFilter>): List<FilterKind> =
        filters.filter { it.enabled && !it.passes(trip) }.map { it.kind }
}
