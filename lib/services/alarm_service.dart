import 'dart:async';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.fajr_alarm/file_picker');
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAlarm(AlarmSettings settings, {bool testMode = false}) async {
    if (_isPlaying) return;

    try {
      await _channel.invokeMethod('playAlarm', {
        'soundPath': settings.alarmSoundPath,
        'volume': settings.volume,
        'vibrate': settings.vibrate,
        'testMode': testMode,
      });
      _isPlaying = true;
    } catch (e) {
      _isPlaying = false;
    }
  }

  Future<void> stopAlarm({bool testMode = false}) async {
    if (!_isPlaying) return;
    await _channel.invokeMethod('stopAlarm', {'testMode': testMode});
    _isPlaying = false;
  }

  Future<void> scheduleAlarm({
    required DateTime fajrTime,
    required AlarmSettings settings,
  }) async {
    final triggerTime = fajrTime.subtract(
      Duration(minutes: settings.reminderMinutesBefore),
    );

    if (triggerTime.isBefore(DateTime.now())) return;

    await _channel.invokeMethod('scheduleAlarm', {
      'triggerAtMillis': triggerTime.millisecondsSinceEpoch,
      'fajrTimeMillis': fajrTime.millisecondsSinceEpoch,
      'soundPath': settings.alarmSoundPath,
      'volume': settings.volume,
      'vibrate': settings.vibrate,
    });
  }

  Future<void> scheduleTestAlarm(int delayMinutes) async {
    final triggerAt = DateTime.now().add(Duration(minutes: delayMinutes));
    final settings = await SettingsService().getSettings();

    await _channel.invokeMethod('scheduleAlarm', {
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      'fajrTimeMillis': triggerAt.millisecondsSinceEpoch,
      'soundPath': settings.alarmSoundPath,
      'volume': settings.volume,
      'vibrate': settings.vibrate,
    });
  }

  Future<void> cancelAlarm() async {
    await _channel.invokeMethod('cancelAlarm');
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
