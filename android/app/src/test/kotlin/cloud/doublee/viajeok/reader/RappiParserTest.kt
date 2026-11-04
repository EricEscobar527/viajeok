package cloud.doublee.viajeok.reader

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * SoyRappi new-order cards: exact on-device OCR of real screenshots
 * (Nov 2026), misreads included. Rappi shows no time, only the route's
 * total km, so only $/km can be judged.
 */
class RappiParserTest {
    private val rappi = ReaderState.RAPPI_COURIER
    private val filters = listOf(
        TripFilter(FilterKind.perHour, enabled = true, value = 150.0),
        TripFilter(FilterKind.perKm, enabled = true, value = 8.0),
        TripFilter(FilterKind.maxPickupKm, enabled = true, value = 3.0),
    )

    private val autoAccepted = listOf(
        "Autop NMéxico", "BUENAVIS TA", "Autoaceptando", "Alta demanda 5 Pts", "SANTA CLARA",
        "Diamantes reciben más pedidos", "Nuevo pedido", "Restaurante", "2.4 km", "1 pedido en la ruta",
        "$24.00", "Puede contener propina...", "En tu incentivo asegurado", "Revisa el avance al finalizar",
        "Little Caesars Santa Clara (A)", "Jardines de Casa Nueva, 55420", "8 Entrega a Oscar R.",
        "Abasolo #212", "Comenzar",
    )

    @Test
    fun restaurantOrder() {
        val o = TripParser.parse(autoAccepted, rappi)!!
        assertEquals(24.0, o.fare, 0.001)
        assertEquals(2.4, o.totalKm, 0.001)
        assertFalse(o.hasTime)
        assertFalse(o.hasPickup)
        assertEquals(10.0, o.perKm, 0.001)
        assertEquals(0.0, o.perHour, 0.001)
        // $/h and pickup can't be judged: only Por km applies, and it passes.
        assertTrue(TripEvaluator.failed(o, filters).isEmpty())
    }

    @Test
    fun rainBonusIsPartOfTheFare() {
        val o = TripParser.parse(
            listOf(
                "TAXQUENA", "COAPA", "Nuevo pedido", "Restaurante", "4.2 km", "1pedido en la ruta", "$38.30",
                "S Ganancia por lluvia incluída", "Panda Express - Paseo Acoxpa", "Calz Acoxpa 430, Coapa, Ex-Hacienda",
                "Coapa, Tlalpan, 14300 Ciudad de México,", "8 Entrega a Manu T.", "Aceptar pedido", "20",
            ),
            rappi,
        )!!
        assertEquals(38.30, o.fare, 0.001)
        assertEquals(9.12, o.perKm, 0.01)
    }

    @Test
    fun superOrderFailsOnlyPerKm() {
        val o = TripParser.parse(
            listOf(
                "7:03 PM", "ACUITLAPILC", "Alta demanda 5 Pts", "NUEVO PEDIDO", "Rechazar", "1entrega en la ruta",
                "Super / Tienda", "$33.00", "6.4 km", "1 producto·1 und· Tú seleccionas",
                "D Soriana Mercado, Peñon - 426_Super", "Mz A Lt8b", "Recibes efectivo", "Aceptar pedido 14",
            ),
            rappi,
        )!!
        assertEquals(33.0, o.fare, 0.001)
        assertEquals(6.4, o.totalKm, 0.001)
        // $5.16/km; never Por hora or Pickup máx.
        assertEquals(listOf(FilterKind.perKm), TripEvaluator.failed(o, filters))
    }

    @Test
    fun distanceChipWithoutPointGetsItsDecimalBack() {
        // "$51.00 9.1 km": at full screen size OCR drops the point.
        val lines = listOf(
            "NUEVO PEDIDO", "Rechazar", "lentrega en la ruta", "Restaurante", "$51.00", "91 km",
            "m Huan Oriental - Zapopan Centro", "Aceptar pedido 21",
        )
        val o = TripParser.parse(lines, rappi)!!
        assertEquals(9.1, o.totalKm, 0.001)
        assertEquals(5.60, o.perKm, 0.01)
        assertEquals(12.0, TripParser.parse(listOf("Nuevo pedido", "$60.00", "120 km"), rappi)!!.totalKm, 0.001)
        assertEquals(2.0, TripParser.parse(listOf("Nuevo pedido", "$21.00", "2.0 km"), rappi)!!.totalKm, 0.001)
        // At half size it read no digits at all ("A km"): no offer rather than a wrong one.
        assertNull(TripParser.parse(listOf("NUEVO PEDIDO", "$51.00", "A km", "Aceptar pedido 21"), rappi))
    }

    @Test
    fun otherRappiScreensAreNotOffers() {
        // An order in progress also has a fare and a distance, but no new-order header.
        assertNull(TripParser.parse(listOf("Restaurante", "$24.00", "2.4 km", "Comenzar"), rappi))
    }

    @Test
    fun rappiFormatNeverAppliesToDidiOrUber() {
        // A Rappi-looking screen read while DiDi or Uber is in front: no legs, no offer.
        assertNull(TripParser.parse(autoAccepted, ReaderState.DIDI_DRIVER))
        assertNull(TripParser.parse(autoAccepted, ReaderState.UBER_DRIVER))
        assertNull(TripParser.parse(autoAccepted))
        // And DiDi/Uber cards read the same with or without the app.
        val didi = listOf("$46.04", "8 min (1.8 km)", "24 min (8.7 km)", "Aceptar $46.04")
        assertEquals(TripParser.parse(didi), TripParser.parse(didi, ReaderState.DIDI_DRIVER))
        assertEquals(TripParser.parse(didi), TripParser.parse(didi, ReaderState.UBER_DRIVER))
        assertTrue(TripParser.parse(didi, ReaderState.DIDI_DRIVER)!!.hasTime)
    }

    @Test
    fun legsIdentifyTheSameRappiCardWhenFareIsCovered() {
        val withFare = TripParser.parse(autoAccepted, rappi)!!
        assertEquals(withFare.legs, TripParser.legs(autoAccepted.filter { it != "$24.00" }, rappi))
    }
}
