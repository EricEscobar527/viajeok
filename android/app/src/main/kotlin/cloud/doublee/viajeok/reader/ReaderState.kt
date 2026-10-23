package cloud.doublee.viajeok.reader

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Settings pushed from Flutter (via MainActivity) plus the running flag,
 * stored natively so the accessibility service can read them without a
 * Flutter engine.
 */
class ReaderState(context: Context) {
    private val prefs = context.getSharedPreferences("trip_reader", Context.MODE_PRIVATE)

    var running: Boolean
        get() = prefs.getBoolean("running", false)
        set(v) = prefs.edit().putBoolean("running", v).apply()

    /** The supported ride apps are fixed; the user can't change them. */
    val packages: Set<String> = setOf(DIDI_DRIVER, UBER_DRIVER)

    val filters: List<TripFilter>
        get() {
            val json = JSONArray(prefs.getString("filters", "[]"))
            return (0 until json.length()).mapNotNull { i ->
                val o = json.getJSONObject(i)
                val kind = FilterKind.entries.firstOrNull { it.name == o.getString("kind") }
                kind?.let { TripFilter(it, o.getBoolean("enabled"), o.getDouble("value")) }
            }
        }

    /** [config] = {filters: [{kind, enabled, value}]} */
    fun setConfig(config: Map<*, *>) {
        prefs.edit()
            .putString("filters", JSONArray((config["filters"] as List<*>).map { JSONObject(it as Map<*, *>) }).toString())
            .apply()
    }

    companion object {
        const val DIDI_DRIVER = "com.didiglobal.driver"
        const val UBER_DRIVER = "com.ubercab.driver"
    }
}
