package cloud.doublee.viajeok.reader

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Uber Driver offer cards, from real screenshots (Mexico, 2026). */
class UberParserTest {
    private val filters = listOf(
        TripFilter(FilterKind.perHour, enabled = true, value = 150.0),
        TripFilter(FilterKind.perKm, enabled = true, value = 8.0),
        TripFilter(FilterKind.maxPickupKm, enabled = true, value = 3.0),
    )

    // Moto ride while navigating: the turn-by-turn banner sits above the card.
    private val motoNavigating = listOf(
        "0 m", "Avenida General", "Francisco Morazán", "Farmacias Guadalajara",
        "Av. 8 266, Ignacio Zaragoza,", "Venustiano Carranza, 15000 Ciudad", "de México, CDMX",
        "México", "134D", "Coyoacán", "15D",
        "Moto", "Exclusivo", "MXN209.86", "Identidad verificada", "4.78 (602)",
        "A 8 min (3.8 km)", "centeno, Autódromo", "Viaje: 1 h 25 min (32.8 km)",
        "Avenida Leandro Valle 66, San Lorenzo", "Acopilco, 05410 Cuajimalpa de",
        "Morelos, Ciudad de México, MX", "Viaje largo (60+ min)", "Aceptar",
    )

    @Test
    fun motoWithMxnPrefixAndHours() {
        val o = TripParser.parse(motoNavigating)!!
        assertEquals(209.86, o.fare, 0.001)
        assertEquals(8.0, o.pickupMinutes, 0.001)
        assertEquals(3.8, o.pickupKm, 0.001)
        assertEquals(85.0, o.tripMinutes, 0.001)
        assertEquals(32.8, o.tripKm, 0.001)
        assertTrue(o.hasPickup)
        // 36.6 km / 93 min → $5.73/km, $135.39/h, pickup 3.8 > 3.
        assertEquals(listOf(FilterKind.perHour, FilterKind.perKm, FilterKind.maxPickupKm), TripEvaluator.failed(o, filters))
    }

    @Test
    fun motoSecondCard() {
        val o = TripParser.parse(
            listOf(
                "Naucalpan de", "Juárez", "Ciudad de", "México", "Moto", "Exclusivo", "MXN182.93",
                "Identidad verificada", "4.78 (602)", "A 5 min (2.5 km)", "centeno, Autódromo",
                "Viaje: 1 h 7 min (31.9 km)", "Avenida Leandro Valle 66, San Lorenzo", "Aceptar",
            ),
        )!!
        assertEquals(182.93, o.fare, 0.001)
        assertEquals(2.5, o.pickupKm, 0.001)
        assertEquals(67.0, o.tripMinutes, 0.001)
        // 34.4 km / 72 min → $5.32/km (fails), $152.44/h (passes), pickup ok.
        assertEquals(listOf(FilterKind.perKm), TripEvaluator.failed(o, filters))
    }

    @Test
    fun uberXIgnoresRateAndIncludedBonus() {
        val o = TripParser.parse(
            listOf(
                "UberX", "Exclusivo", "$152.75", "$14.83/km (estimado)", "Identidad verificada",
                "4.79 (142)", "+$8.00 incluido", "7 min (3.3 km)",
                "Blv Manuel Ávila Camacho 460", "Edificio C Piso 1er - Naucalpan",
                "14 min (7.0 km)", "Calle Hacienda de Chimalpa 6,", "Hacia tu destino", "Aceptar",
            ),
        )!!
        assertEquals(152.75, o.fare, 0.001)
        assertEquals(3.3, o.pickupKm, 0.001)
        assertEquals(7.0, o.tripKm, 0.001)
        // 10.3 km / 21 min → $14.83/km, $436.43/h; only pickup 3.3 > 3 fails.
        assertEquals(14.83, o.perKm, 0.01)
        assertEquals(listOf(FilterKind.maxPickupKm), TripEvaluator.failed(o, filters))
    }

    @Test
    fun fareIsNotTakenFromRateOrBonusEvenIfTheyComeFirst() {
        val o = TripParser.parse(
            listOf("+$8.00 incluido", "$14.83/km (estimado)", "$152.75", "7 min (3.3 km)", "14 min (7.0 km)"),
        )!!
        assertEquals(152.75, o.fare, 0.001)
    }

    @Test
    fun deliveryWithTotalLeg() {
        val o = TripParser.parse(
            listOf(
                "Parque del Pueblo", "Los Reyes", "Acaquilpan", "150D", "Entrega", "Exclusivo",
                "MXN60.33", "Total: 42 min (14.2 km)", "Eduardo's Pizza",
                "Calle Maravillas & Calle Nayarit", "Aceptar", "San Juan",
            ),
        )!!
        assertEquals(60.33, o.fare, 0.001)
        assertFalse(o.hasPickup)
        assertEquals(42.0, o.totalMinutes, 0.001)
        assertEquals(14.2, o.totalKm, 0.001)
        // Pickup can't be judged on a delivery: only the rate filters apply.
        assertEquals(listOf(FilterKind.perHour, FilterKind.perKm), TripEvaluator.failed(o, filters))
    }

    @Test
    fun deliveryWholePesosAndTipNote() {
        val o = TripParser.parse(
            listOf(
                "85D", "132D", "85", "Entrega", "Exclusivo", "MXN44", "Puede incluir propinas",
                "Total: 26 min (11.4 km)", "Tim Hortons (Lechería)", "Privada Valle de Atenco 31B,",
                "Tepexpan", "Aceptar",
            ),
        )!!
        assertEquals(44.0, o.fare, 0.001)
        assertEquals(11.4, o.totalKm, 0.001)
        assertEquals(26.0, o.totalMinutes, 0.001)
    }

    @Test
    fun deliveryPassesPickupFilterEvenWhenVeryStrict() {
        val o = TripParser.parse(listOf("MXN300", "Total: 20 min (10.0 km)"))!!
        val strict = listOf(TripFilter(FilterKind.maxPickupKm, enabled = true, value = 0.5))
        assertTrue(TripEvaluator.failed(o, strict).isEmpty())
    }

    @Test
    fun ocrVariants() {
        // "MXN 209.86" with a space, the leg split from its label, $ glued to MXN.
        val o = TripParser.parse(listOf("MXN 209.86", "A", "8 min (3.8 km)", "Viaje:", "1 h 25 min (32.8 km)"))!!
        assertEquals(209.86, o.fare, 0.001)
        assertEquals(85.0, o.tripMinutes, 0.001)
        assertEquals(182.93, TripParser.parse(listOf("MXN$182.93", "A 5 min (2.5 km)", "Viaje: 1 h 7 min (31.9 km)"))!!.fare, 0.001)
    }

    // Exact on-device OCR of real screenshots (Oct 2026), misreads included.

    @Test
    fun surgeChipsOnTheMapAreNotTheFare() {
        val o = TripParser.parse(
            listOf(
                "Cole", "articuila", "Instituto de", "******", "Estudios", "Superiore", "4 1.3~2.4x", "4 1.3",
                "15 DE ocr", "4 1.5-2.4x", "Uber", "MEX-150D", "$ 1.3~1.4x", "Instituto", "$ 1.3-1.6x",
                "cnológico de Puebla", "UberX", "X", "MXN85.01", "ldentidad verificada", "★ 4.40 (22)", "1:",
                "9 +MXN12.00 incluido", "A 14 min (5.0 km)", "Calle Uva, Los Álamos", "Viaje: 17 min (6.1 km)",
                "Valle de Juárez 6826, Col del Valle,", "Viaje disponible",
            ),
        )!!
        assertEquals(85.01, o.fare, 0.001)
        // 11.1 km / 31 min → $7.66/km, $164.54/h.
        assertEquals(7.66, o.perKm, 0.01)
        assertEquals(164.54, o.perHour, 0.01)
        assertEquals(80.09, TripParser.parse(listOf("($1215x", "$ 1.2-1.5x", "MXN80.09", "A 14 min (5.3 km)", "Viaje: 1l min (6.3 km)"))!!.fare, 0.001)
    }

    @Test
    fun motoWithTurboAndExtraAmountAndKmMisread() {
        val o = TripParser.parse(
            listOf(
                "Avenida Gustavo Baz Prada", "0.9 km", "Moto", "Exclusivo", "X", "$95.42", "4.83 (981)",
                "Identidad verificada", "G", "+$7.25 incluido $14.91 Turbo+ incluido",
                "Incluye un monto extra de $11", "7 min (2.6 km)", "yo",
                "Calle Alcatraz - Jardines del Molinito - Naucalpan", "h 22 min (9.4 knm)", "Aceptar",
            ),
        )!!
        assertEquals(95.42, o.fare, 0.001)
        assertEquals(2.6, o.pickupKm, 0.001)
        assertEquals(22.0, o.tripMinutes, 0.001)
        assertEquals(9.4, o.tripKm, 0.001)
    }

    @Test
    fun motoLegsWithoutPrefixesAndSummaryLine() {
        val o = TripParser.parse(
            listOf(
                "3 Moto", "X", "$184.94", "lh 17 min 42.9 km", "4.86 (370)", "Identidad verificada",
                "18 min (8.7 km)", "Calle Sauce - Los Héroes Tecamac - Ecatepec", "59 min (34.2 km)",
                "SỰ Viaje largo (60+ min)", "Me interesa",
            ),
        )!!
        // Same totals as Uber's own summary line: 1 h 17 min, 42.9 km.
        assertEquals(77.0, o.totalMinutes, 0.001)
        assertEquals(42.9, o.totalKm, 0.001)
        assertEquals(4.31, o.perKm, 0.01)
    }

    @Test
    fun deliveryWholePesosWithDollarSign() {
        val o = TripParser.parse(
            listOf("Y? Entrega", "X", "hte", "$125", "Puede incluir propinas", "9 Total: 43 min (21.5 km)", "Me interesa"),
        )!!
        assertEquals(125.0, o.fare, 0.001)
        assertFalse(o.hasPickup)
        assertEquals(174.42, o.perHour, 0.01)
    }

    @Test
    fun ratingsAndCountsAreNeverFares() {
        assertNull(TripParser.parse(listOf("4.78 (602)", "A 8 min (3.8 km)", "Viaje: 1 h 25 min (32.8 km)")))
    }

    @Test
    fun legsAloneIdentifyTheSameCardWhenFareIsCovered() {
        val withFare = TripParser.parse(listOf("$152.75", "7 min (3.3 km)", "14 min (7.0 km)"))!!
        // Later poll: our popup covers the price, legs still visible.
        assertNull(TripParser.parse(listOf("7 min (3.3 km)", "14 min (7.0 km)")))
        assertEquals(withFare.legs, TripParser.legs(listOf("7 min (3.3 km)", "14 min (7.0 km)")))
    }
}
