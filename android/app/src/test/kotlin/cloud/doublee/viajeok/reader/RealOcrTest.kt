package cloud.doublee.viajeok.reader

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

/**
 * Lines exactly as on-device ML Kit OCR returned them for real offer
 * screenshots (via DebugOfferActivity), including its misreads.
 */
class RealOcrTest {
    @Test
    fun uberPackageWithHourReadAsLetterL() {
        // "1 h 44 min" came back as "lh 44 min".
        val lines = listOf(
            "Paquete Exclusivo", "X", "\$235.85", "5.00 (22)", "Identidad verificada",
            "° 10 min (4.1 km)", "Cerrada V. Guerrero - Satélite/Lomas Verdes",
            "lh 44 min (49.7 km)", "Calle Ixchel, Santa Catarina Yecahuizotl, Valle",
            "A3 Viaje largo (60+ min)", "Aceptar",
        )
        val o = TripParser.parse(lines)!!
        assertEquals(235.85, o.fare, 0.001)
        assertEquals(10.0, o.pickupMinutes, 0.001)
        assertEquals(4.1, o.pickupKm, 0.001)
        assertEquals(104.0, o.tripMinutes, 0.001)
        assertEquals(49.7, o.tripKm, 0.001)
    }

    @Test
    fun didiOfferWithMetersPickup() {
        val lines = listOf(
            "X Rechazo permitido", "Pon Tu Precio", "\$67.80", "1 punto", "* 4.94 53 viajes",
            "Tarjeta bancaria verificada", "6 min (812 m)", "CerradaT. Mayor 3, Sta Maria",
            "32 min (9.2 km)", "Salón Las Fuentes Cuautitlan, El", "Aceptar \$67.80",
            "\$72.80 \$75.80 \$78.80", "42",
        )
        val o = TripParser.parse(lines)!!
        assertEquals(67.80, o.fare, 0.001)
        assertEquals(0.812, o.pickupKm, 0.001)
        assertEquals(9.2, o.tripKm, 0.001)
        assertEquals(38.0, o.totalMinutes, 0.001)
    }

    @Test
    fun didiOfferWithOurPopupAndLetterOBeforeMinutes() {
        // Our own popup text is on screen too ("$9.90/km …"), and "9 min" came
        // back as "O9 min". The fare must still come from "Aceptar $28.27".
        val lines = listOf(
            "X Rechazo permitido", "\$9.90/km \$141.35/h", "\$28.27 · 2.9 km 12 min",
            "Pon Tu Precio", "\$28.27 1.2x", "O9 min (2 km)", "3 min (856 m)",
            "Aceptar \$28.27", "A \$30.27 \$31.27 \$33.27",
        )
        val o = TripParser.parse(lines)!!
        assertEquals(28.27, o.fare, 0.001)
        assertEquals(9.0, o.pickupMinutes, 0.001)
        assertEquals(2.0, o.pickupKm, 0.001)
        assertEquals(0.856, o.tripKm, 0.001)
    }

    @Test
    fun uberDeliveryWholePesos() {
        val lines = listOf(
            "? Entrega", "Exclusivo", "X", "\$126", "Puede incluir propinas",
            ") Total: 47 min (24.7 km)", "El Jardincito", "Aceptar",
        )
        val o = TripParser.parse(lines)!!
        assertEquals(126.0, o.fare, 0.001)
        assertFalse(o.hasPickup)
        assertEquals(47.0, o.tripMinutes, 0.001)
        assertEquals(24.7, o.tripKm, 0.001)
    }

    @Test
    fun digitLookAlikesAreFixedOnlyInsideNumbers() {
        assertEquals("1h 44 min (49.7 km)", TripParser.ocrDigits("lh 44 min (49.7 km)"))
        assertEquals("10 min (4.1 km)", TripParser.ocrDigits("1O min (4.l km)"))
        assertEquals("09 min (2 km)", TripParser.ocrDigits("O9 min (2 km)"))
        // Words, even with I/l/O in them, stay as they are.
        assertEquals("Iztapalapa Lomas Verdes", TripParser.ocrDigits("Iztapalapa Lomas Verdes"))
        assertEquals("Total: 47 min", TripParser.ocrDigits("Total: 47 min"))
    }
}
