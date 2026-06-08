import 'dart:async';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.fajr_alarm/file_picker');
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAlarm(AlarmSettings settings) async {
    if (_isPlaying) return;

    try {
      await _channel.invokeMethod('playAlarm', {
        'soundPath': settings.alarmSoundPath,
        'volume': settings.volume,
        'vibrate': settings.vibrate,
      });
      _isPlaying = true;
    } catch (e) {
      _isPlaying = false;
    }
  }

  Future<void> stopAlarm() async {
    if (!_isPlaying) return;
    await _channel.invokeMethod('stopAlarm');
    _isPlaying = false;
  }

  Future<String?> pickAudioFile() async {
    try {
      final result = await _channel.invokeMethod<String>('pickAudioFile');
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getDisplayName(String uri) async {
    try {
      final result = await _channel.invokeMethod<String>('getDisplayName', {
        'uri': uri,
      });
      return result;
    } catch (_) {
      return null;
    }
  }
}
