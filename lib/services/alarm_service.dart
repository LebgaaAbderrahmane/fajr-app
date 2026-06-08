import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.fajr_alarm/file_picker');
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _usingNative = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAlarm(AlarmSettings settings) async {
    if (_isPlaying) return;

    try {
      if (settings.alarmSoundPath.startsWith('content://') ||
          settings.alarmSoundPath.startsWith('/')) {
        _usingNative = false;
        if (settings.alarmSoundPath.startsWith('content://')) {
          await _player.setUrl(settings.alarmSoundPath);
        } else {
          await _player.setFilePath(settings.alarmSoundPath);
        }
        await _player.setVolume(settings.volume / 100.0);
        await _player.setLoopMode(LoopMode.one);
        await _player.play();
      } else {
        _usingNative = true;
        await _channel.invokeMethod('playSystemAlarm', {
          'type': 1,
          'volume': settings.volume,
        });
      }

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

    if (_usingNative) {
      await _channel.invokeMethod('stopSystemAlarm');
    } else {
      await _player.stop();
    }

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
}
