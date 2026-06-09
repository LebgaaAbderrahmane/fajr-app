import 'package:shared_preferences/shared_preferences.dart';

class AlarmSettings {
  final String alarmSoundPath;
  final String? alarmSoundName;
  final int volume;
  final bool vibrate;
  final int reminderMinutesBefore;
  final bool isEnabled;
  final bool hardMode;

  const AlarmSettings({
    this.alarmSoundPath = 'default',
    this.alarmSoundName,
    this.volume = 80,
    this.vibrate = true,
    this.reminderMinutesBefore = 10,
    this.isEnabled = true,
    this.hardMode = true,
  });

  AlarmSettings copyWith({
    String? alarmSoundPath,
    String? alarmSoundName,
    int? volume,
    bool? vibrate,
    int? reminderMinutesBefore,
    bool? isEnabled,
    bool? hardMode,
  }) {
    return AlarmSettings(
      alarmSoundPath: alarmSoundPath ?? this.alarmSoundPath,
      alarmSoundName: alarmSoundName ?? this.alarmSoundName,
      volume: volume ?? this.volume,
      vibrate: vibrate ?? this.vibrate,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      isEnabled: isEnabled ?? this.isEnabled,
      hardMode: hardMode ?? this.hardMode,
    );
  }
}

class SettingsService {
  static const String _soundKey = 'alarm_sound_path';
  static const String _soundNameKey = 'alarm_sound_name';
  static const String _volumeKey = 'alarm_volume';
  static const String _vibrateKey = 'alarm_vibrate';
  static const String _reminderKey = 'alarm_reminder_minutes';
  static const String _enabledKey = 'alarm_enabled';
  static const String _hardModeKey = 'alarm_hard_mode';

  Future<void> saveSettings(AlarmSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundKey, settings.alarmSoundPath);
    if (settings.alarmSoundName != null) {
      await prefs.setString(_soundNameKey, settings.alarmSoundName!);
    } else {
      await prefs.remove(_soundNameKey);
    }
    await prefs.setInt(_volumeKey, settings.volume);
    await prefs.setBool(_vibrateKey, settings.vibrate);
    await prefs.setInt(_reminderKey, settings.reminderMinutesBefore);
    await prefs.setBool(_enabledKey, settings.isEnabled);
    await prefs.setBool(_hardModeKey, settings.hardMode);
  }

  Future<AlarmSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AlarmSettings(
      alarmSoundPath: prefs.getString(_soundKey) ?? 'default',
      alarmSoundName: prefs.getString(_soundNameKey),
      volume: prefs.getInt(_volumeKey) ?? 80,
      vibrate: prefs.getBool(_vibrateKey) ?? true,
      reminderMinutesBefore: prefs.getInt(_reminderKey) ?? 10,
      isEnabled: prefs.getBool(_enabledKey) ?? true,
      hardMode: prefs.getBool(_hardModeKey) ?? true,
    );
  }
}
