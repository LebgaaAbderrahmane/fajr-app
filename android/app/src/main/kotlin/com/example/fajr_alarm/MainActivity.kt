package com.example.fajr_alarm

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fajr_alarm/file_picker"
    private val PICK_AUDIO_REQUEST = 1001
    private var resultPending: MethodChannel.Result? = null
    private var currentRingtone: android.media.Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playSystemAlarm" -> {
                        val type = call.argument<Int>("type") ?: 0
                        val volume = call.argument<Int>("volume") ?: 80
                        playSystemAlarm(type, volume)
                        result.success(null)
                    }
                    "stopSystemAlarm" -> {
                        stopSystemAlarm()
                        result.success(null)
                    }
                    "pickAudioFile" -> {
                        resultPending = result
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "audio/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(
                            Intent.createChooser(intent, "Select Audio"),
                            PICK_AUDIO_REQUEST
                        )
                    }
                    "vibrate" -> {
                        vibrate()
                        result.success(null)
                    }
                    "stopVibrate" -> {
                        stopVibrate()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun playSystemAlarm(type: Int, volume: Int) {
        stopSystemAlarm()
        val uri = when (type) {
            1 -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            2 -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        }
        if (uri != null) {
            currentRingtone = RingtoneManager.getRingtone(applicationContext, uri)
            currentRingtone?.let {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    it.isLooping = true
                }
                it.play()
            }
        }
    }

    private fun stopSystemAlarm() {
        currentRingtone?.let {
            if (it.isPlaying) it.stop()
        }
        currentRingtone = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_AUDIO_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri = data.data!!
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                } catch (_: SecurityException) {}
                resultPending?.success(uri.toString())
            } else {
                resultPending?.success(null)
            }
            resultPending = null
        }
    }

    private fun vibrate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(VibratorManager::class.java)
            vibratorManager.defaultVibrator.vibrate(
                VibrationEffect.createWaveform(longArrayOf(0, 500, 300, 500), 0)
            )
        } else {
            @Suppress("DEPRECATION")
            val vibrator = getSystemService(Vibrator::class.java)
            @Suppress("DEPRECATION")
            vibrator.vibrate(
                VibrationEffect.createWaveform(longArrayOf(0, 500, 300, 500), 0)
            )
        }
    }

    private fun stopVibrate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator.cancel()
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java).cancel()
        }
    }
}
