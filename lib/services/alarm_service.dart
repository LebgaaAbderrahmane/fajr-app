import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.fajr_alarm/file_picker');
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAlarm(AlarmSettings settings) async {
    if (_isPlaying) return;

    try {
      if (settings.alarmSoundPath.startsWith('content://') ||
          settings.alarmSoundPath.startsWith('/')) {
        if (settings.alarmSoundPath.startsWith('content://')) {
          await _player.setUrl(settings.alarmSoundPath);
        } else {
          await _player.setFilePath(settings.alarmSoundPath);
        }
      } else {
        await _player.setAsset('assets/sounds/${settings.alarmSoundPath}.mp3');
      }

      await _player.setVolume(settings.volume / 100.0);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
      _isPlaying = true;

      if (settings.vibrate) {
        await _startVibration();
      }
    } catch (e) {
      _isPlaying = false;
    }
  }

  Future<void> stopAlarm() async {
    if (!_isPlaying) return;
    await _player.stop();
    _isPlaying = false;
    await _stopVibration();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  Future<void> _startVibration() async {
    try {
      await _channel.invokeMethod('vibrate');
    } catch (_) {}
  }

  Future<void> _stopVibration() async {
    try {
      await _channel.invokeMethod('stopVibrate');
    } catch (_) {}
  }

  Future<String?> pickAudioFile() async {
    try {
      final result = await _channel.invokeMethod<String>('pickAudioFile');
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> testAlarm(AlarmSettings settings) async {
    await playAlarm(settings);
    Future.delayed(const Duration(seconds: 5), () {
      stopAlarm();
    });
  }
}
