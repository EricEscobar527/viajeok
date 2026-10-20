package com.example.analisis_viaje.reader

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Settings pushed from Flutter (via MainActivity) plus session counters,
 * stored natively so the accessibility service can read them without a
 * Flutter engine.
 */
class ReaderState(context: Context) {
    private val prefs = context.getSharedPreferences("trip_reader", Context.MODE_PRIVATE)

    var running: Boolean
        get() = prefs.getBoolean("running", false)
        set(v) = prefs.edit().putBoolean("running", v).apply()

    val packages: Set<String>
        get() = prefs.getStringSet("packages", DEFAULT_PACKAGES) ?: DEFAULT_PACKAGES

    val filters: List<TripFilter>
        get() {
            val json = JSONArray(prefs.getString("filters", "[]"))
            return (0 until json.length()).mapNotNull { i ->
                val o = json.getJSONObject(i)
                val kind = FilterKind.entries.firstOrNull { it.name == o.getString("kind") }
                kind?.let { TripFilter(it, o.getBoolean("enabled"), o.getDouble("value")) }
            }
        }

    /** [config] = {packages: [String], filters: [{kind, enabled, value}]} */
    fun setConfig(config: Map<*, *>) {
        prefs.edit()
            .putStringSet("packages", (config["packages"] as List<*>).map { it.toString() }.toSet())
            .putString("filters", JSONArray((config["filters"] as List<*>).map { JSONObject(it as Map<*, *>) }).toString())
            .apply()
    }

    fun stats(): Map<String, Int> = mapOf(
        "total" to prefs.getInt("total", 0),
        "accepted" to prefs.getInt("accepted", 0),
        "rejected" to prefs.getInt("rejected", 0),
    )

    fun count(accepted: Boolean) {
        val key = if (accepted) "accepted" else "rejected"
        prefs.edit()
            .putInt("total", prefs.getInt("total", 0) + 1)
            .putInt(key, prefs.getInt(key, 0) + 1)
            .apply()
    }

    fun resetStats() {
        prefs.edit().putInt("total", 0).putInt("accepted", 0).putInt("rejected", 0).apply()
    }

    companion object {
        val DEFAULT_PACKAGES = setOf("com.ubercab.driver", "com.didiglobal.driver")
    }
}
