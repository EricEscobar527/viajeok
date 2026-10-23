package cloud.doublee.viajeok.reader

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TripParserTest {
    // Texts as they appear on a DiDi "Pon Tu Precio" offer card.
    private val didi = listOf(
        "Pon Tu Precio", "$46.04", "1.2x", "1 punto", "4.68", "114 viajes",
        "8 min (1.8 km)", "Geranios 9, Valle de las Flores, Cuautitlán Izcalli",
        "24 min (8.7 km)", "Centro de Envío FedEx, San Martín Obispo",
        "Aceptar $46.04", "$47.04", "$49.04", "$50.04",
    )

    @Test
    fun parsesDidiOffer() {
        val o = TripParser.parse(didi)!!
        assertEquals(46.04, o.fare, 0.001)
        assertEquals(8.0, o.pickupMinutes, 0.001)
        assertEquals(1.8, o.pickupKm, 0.001)
        assertEquals(24.0, o.tripMinutes, 0.001)
        assertEquals(8.7, o.tripKm, 0.001)
    }

    @Test
    fun parsesOcrLinesOfDidiCard() {
        // OCR merges the price with the surge badge and splits addresses.
        val lines = listOf(
            "Pon Tu Precio", "$34.52 41.5x", "1 punto", "Nuevo", "Identificación verificada",
            "9 min (2.1 km)", "Fraccionamiento Garzas, Residencial", "Eucalipto, Cuautitlán Izcalli, Ciudad...",
            "13 min (4.6 km)", "SAT Servicio de Administración", "Aceptar $34.52", "$37.52 $38.52 $40.52",
        )
        val o = TripParser.parse(lines)!!
        assertEquals(34.52, o.fare, 0.001)
        assertEquals(2.1, o.pickupKm, 0.001)
        assertEquals(13.0, o.tripMinutes, 0.001)
        assertEquals(4.6, o.tripKm, 0.001)
    }

    @Test
    fun fareComesFromAcceptButtonNotCounterOffers() {
        val o = TripParser.parse(listOf("$50.04", "8 min (1.8 km)", "24 min (8.7 km)", "Aceptar $46.04"))!!
        assertEquals(46.04, o.fare, 0.001)
    }

    @Test
    fun handlesHoursMetersAndThousands() {
        val o = TripParser.parse(listOf("MX$1,046.50", "3 min (800 m)", "1 h 5 min (52,3 km)"))!!
        assertEquals(1046.50, o.fare, 0.001)
        assertEquals(0.8, o.pickupKm, 0.001)
        assertEquals(65.0, o.tripMinutes, 0.001)
        assertEquals(52.3, o.tripKm, 0.001)
    }

    @Test
    fun ignoresScreensWithoutAFullOffer() {
        assertNull(TripParser.parse(listOf("$46.04", "8 min (1.8 km)")))
        assertNull(TripParser.parse(listOf("8 min (1.8 km)", "24 min (8.7 km)")))
    }

    @Test
    fun ratesIncludeThePickupLeg() {
        // $100 over 10 km and 20 min in total → $10/km and $300/h.
        val o = TripOffer(fare = 100.0, pickupMinutes = 5.0, pickupKm = 2.0, tripMinutes = 15.0, tripKm = 8.0)
        assertEquals(10.0, o.perKm, 0.001)
        assertEquals(300.0, o.perHour, 0.001)
    }

    @Test
    fun evaluatorReportsOnlyEnabledFailingFilters() {
        val o = TripOffer(fare = 100.0, pickupMinutes = 5.0, pickupKm = 2.0, tripMinutes = 15.0, tripKm = 8.0)
        val failed = TripEvaluator.failed(
            o,
            listOf(
                TripFilter(FilterKind.perKm, enabled = true, value = 12.0),
                TripFilter(FilterKind.maxPickupKm, enabled = true, value = 1.0),
                TripFilter(FilterKind.perHour, enabled = true, value = 100.0),
                TripFilter(FilterKind.perHour, enabled = false, value = 999.0),
            ),
        )
        assertEquals(listOf(FilterKind.perKm, FilterKind.maxPickupKm), failed)
        assertTrue(TripEvaluator.failed(o, emptyList()).isEmpty())
    }
}
