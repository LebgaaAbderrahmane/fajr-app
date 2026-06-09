package com.example.fajr_alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmForegroundService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var currentRingtone: android.media.Ringtone? = null
    private var vibrator: Vibrator? = null

    companion object {
        const val TAG = "AlarmForegroundService"
        const val CHANNEL_ID = "fajr_alarm_channel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START = "com.fajr_alarm.START_ALARM"
        const val ACTION_STOP = "com.fajr_alarm.STOP_ALARM"
        const val EXTRA_SOUND_PATH = "sound_path"
        const val EXTRA_VOLUME = "volume"
        const val EXTRA_VIBRATE = "vibrate"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                val soundPath = intent.getStringExtra(EXTRA_SOUND_PATH) ?: "default"
                val volume = intent.getIntExtra(EXTRA_VOLUME, 80)
                val vibrate = intent.getBooleanExtra(EXTRA_VIBRATE, true)

                val notification = buildNotification()
                try {
                    startForeground(NOTIFICATION_ID, notification)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start foreground", e)
                }
                playAlarm(soundPath, volume, vibrate)
            }
        }
        return START_STICKY
    }

    private fun buildNotification(): Notification {
        val stopIntent = Intent(this, AlarmForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Fajr Alarm")
            .setContentText("Alarm is ringing")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(openPendingIntent)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .build()
    }

    private fun playAlarm(soundPath: String, volume: Int, vibrate: Boolean) {
        stopAudio()

        val vol = volume / 100.0f

        try {
            if (soundPath.startsWith("content://")) {
                val uri = android.net.Uri.parse(soundPath)
                mediaPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    setDataSource(applicationContext, uri)
                    isLooping = true
                    setVolume(vol, vol)
                    setOnErrorListener { _, what, extra ->
                        Log.e(TAG, "MediaPlayer error: what=$what extra=$extra")
                        reset()
                        try {
                            setAudioAttributes(
                                AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_ALARM)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                    .build()
                            )
                            setDataSource(applicationContext, uri)
                            prepare()
                            start()
                        } catch (e: Exception) {
                            Log.e(TAG, "Retry failed, falling back to default alarm", e)
                            playDefaultAlarm(vol)
                        }
                        true
                    }
                    prepare()
                    start()
                }
            } else if (soundPath.startsWith("/")) {
                mediaPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    setDataSource(soundPath)
                    isLooping = true
                    setVolume(vol, vol)
                    prepare()
                    start()
                }
            } else {
                playDefaultAlarm(vol)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play alarm sound: $soundPath", e)
            playDefaultAlarm(vol)
        }

        if (vibrate) {
            startVibration()
        }
    }

    private fun playDefaultAlarm(vol: Float) {
        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            if (uri != null) {
                currentRingtone = RingtoneManager.getRingtone(applicationContext, uri)
                currentRingtone?.let {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        it.isLooping = true
                    }
                    it.play()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play default alarm", e)
        }
    }

    private fun startVibration() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(VibratorManager::class.java)
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java)
        }
        vibrator?.vibrate(
            VibrationEffect.createWaveform(longArrayOf(0, 500, 300, 500), 0)
        )
    }

    private fun stopAudio() {
        mediaPlayer?.let {
            try {
                if (it.isPlaying) it.stop()
            } catch (_: Exception) {}
            it.release()
        }
        mediaPlayer = null

        currentRingtone?.let {
            try {
                if (it.isPlaying) it.stop()
            } catch (_: Exception) {}
        }
        currentRingtone = null

        vibrator?.cancel()
        vibrator = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Fajr Alarm",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Fajr prayer alarm notification"
                setBypassDnd(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 300, 500)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        stopAudio()
        super.onDestroy()
    }
}
