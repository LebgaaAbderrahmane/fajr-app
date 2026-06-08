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
    private var testMediaPlayer: MediaPlayer? = null
    private var testRingtone: android.media.Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playAlarm" -> {
                        val soundPath = call.argument<String>("soundPath") ?: "default"
                        val volume = call.argument<Int>("volume") ?: 80
                        val useVibrate = call.argument<Boolean>("vibrate") ?: true
                        val testMode = call.argument<Boolean>("testMode") ?: false
                        if (testMode) {
                            playTestAlarm(soundPath, volume, useVibrate)
                        } else {
                            startForegroundAlarm(soundPath, volume, useVibrate)
                        }
                        result.success(null)
                    }
                    "stopAlarm" -> {
                        val testMode = call.argument<Boolean>("testMode") ?: false
                        if (testMode) {
                            stopTestAlarm()
                        } else {
                            stopForegroundAlarm()
                        }
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
                    "getDisplayName" -> {
                        val uriStr = call.argument<String>("uri") ?: ""
                        val name = getDisplayNameFromUri(uriStr)
                        result.success(name)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun playTestAlarm(soundPath: String, volume: Int, vibrate: Boolean) {
        stopTestAlarm()
        val vol = volume / 100.0f

        try {
            if (soundPath.startsWith("content://")) {
                val uri = android.net.Uri.parse(soundPath)
                testMediaPlayer = MediaPlayer().apply {
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
                testMediaPlayer = MediaPlayer().apply {
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
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                if (uri != null) {
                    testRingtone = RingtoneManager.getRingtone(applicationContext, uri)
                    testRingtone?.let {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            it.isLooping = true
                        }
                        it.play()
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        if (vibrate) {
            startVibration()
        }
    }

    private fun stopTestAlarm() {
        testMediaPlayer?.let {
            try { if (it.isPlaying) it.stop() } catch (_: Exception) {}
            it.release()
        }
        testMediaPlayer = null

        testRingtone?.let {
            try { if (it.isPlaying) it.stop() } catch (_: Exception) {}
        }
        testRingtone = null

        stopVibration()
    }

    private fun startForegroundAlarm(soundPath: String, volume: Int, vibrate: Boolean) {
        val intent = Intent(this, AlarmForegroundService::class.java).apply {
            action = AlarmForegroundService.ACTION_START
            putExtra(AlarmForegroundService.EXTRA_SOUND_PATH, soundPath)
            putExtra(AlarmForegroundService.EXTRA_VOLUME, volume)
            putExtra(AlarmForegroundService.EXTRA_VIBRATE, vibrate)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopForegroundAlarm() {
        val intent = Intent(this, AlarmForegroundService::class.java).apply {
            action = AlarmForegroundService.ACTION_STOP
        }
        startService(intent)
    }

    private fun getDisplayNameFromUri(uriStr: String): String? {
        if (uriStr.isEmpty()) return null
        val uri = android.net.Uri.parse(uriStr)
        if (uri.scheme == "content") {
            val cursor = contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (nameIndex >= 0) {
                        return it.getString(nameIndex)
                    }
                }
            }
        }
        return uri.lastPathSegment
    }

    private fun startVibration() {
        val v = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java)
        }
        v?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 500, 300, 500), 0))
    }

    private fun stopVibration() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator.cancel()
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java).cancel()
        }
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

    override fun onDestroy() {
        stopTestAlarm()
        super.onDestroy()
    }
}
