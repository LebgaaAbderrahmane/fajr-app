package com.example.fajr_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val soundPath = intent.getStringExtra(AlarmScheduler.EXTRA_SOUND_PATH) ?: "default"
        val volume = intent.getIntExtra(AlarmScheduler.EXTRA_VOLUME, 80)
        val vibrate = intent.getBooleanExtra(AlarmScheduler.EXTRA_VIBRATE, true)

        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
            action = AlarmForegroundService.ACTION_START
            putExtra(AlarmForegroundService.EXTRA_SOUND_PATH, soundPath)
            putExtra(AlarmForegroundService.EXTRA_VOLUME, volume)
            putExtra(AlarmForegroundService.EXTRA_VIBRATE, vibrate)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
