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

    /** The user's start/stop choice; reads false while [locked]. */
    var running: Boolean
        get() = prefs.getBoolean("running", false) && !locked
        set(v) = prefs.edit().putBoolean("running", v).apply()

    /**
     * Epoch millis after which analysis stops until the app unlocks it again
     * (subscription lapsed or not bought); 0 = never. Pushed from Dart
     * (lib/billing/) so a lapsed subscription stops even if the app isn't
     * reopened.
     */
    var lockAt: Long
        get() = prefs.getLong("lock_at", 0L)
        set(v) = prefs.edit().putLong("lock_at", v).apply()

    val locked: Boolean
        get() = lockAt in 1..System.currentTimeMillis()

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
