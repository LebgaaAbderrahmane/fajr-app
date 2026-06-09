package com.example.fajr_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            val prefs = context.getSharedPreferences("fajr_alarm_prefs", Context.MODE_PRIVATE)
            val fajrTimeMillis = prefs.getLong("fajr_time_millis", 0)
            val soundPath = prefs.getString("alarm_sound_path", "default") ?: "default"
            val volume = prefs.getInt("alarm_volume", 80)
            val vibrate = prefs.getBoolean("alarm_vibrate", true)
            val isEnabled = prefs.getBoolean("alarm_enabled", true)

            if (isEnabled && fajrTimeMillis > System.currentTimeMillis()) {
                val scheduler = AlarmScheduler(context)
                scheduler.schedule(fajrTimeMillis, soundPath, volume, vibrate)
            }
        }
    }
}
