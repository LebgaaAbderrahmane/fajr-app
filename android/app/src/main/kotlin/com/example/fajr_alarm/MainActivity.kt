package com.example.fajr_alarm

import android.app.Activity
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
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
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playAlarm" -> {
                        val soundPath = call.argument<String>("soundPath") ?: "default"
                        val volume = call.argument<Int>("volume") ?: 80
                        val useVibrate = call.argument<Boolean>("vibrate") ?: true
                        playAlarmNative(soundPath, volume, useVibrate)
                        result.success(null)
                    }
                    "stopAlarm" -> {
                        stopAllAudio()
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

    private fun playAlarmNative(soundPath: String, volume: Int, useVibrate: Boolean) {
        stopAllAudio()

        val vol = volume / 100.0f

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
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
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

        if (useVibrate) {
            vibrate()
        }
    }

    private fun stopAllAudio() {
        mediaPlayer?.let {
            if (it.isPlaying) it.stop()
            it.release()
        }
        mediaPlayer = null

        currentRingtone?.let {
            if (it.isPlaying) it.stop()
        }
        currentRingtone = null

        stopVibrate()
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

    override fun onDestroy() {
        stopAllAudio()
        super.onDestroy()
    }
}
