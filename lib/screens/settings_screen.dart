import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  AlarmSettings _settings = const AlarmSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _settingsService.saveSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _pickAlarmSound() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _settings = _settings.copyWith(
            alarmSoundPath: result.files.single.path!,
          );
        });
        await _saveSettings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _resetToDefault() {
    setState(() {
      _settings = const AlarmSettings();
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
            onPressed: _resetToDefault,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Enable Alarm'),
              subtitle: const Text('Turn Fajr alarm on or off'),
              value: _settings.isEnabled,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(isEnabled: value);
                });
                _saveSettings();
              },
              secondary: Icon(
                _settings.isEnabled ? Icons.alarm : Icons.alarm_off,
                color: _settings.isEnabled ? Colors.indigo : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Alarm Sound'),
              subtitle: Text(
                _settings.alarmSoundPath == 'default'
                    ? 'Default Adhan'
                    : _settings.alarmSoundPath.split('/').last,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickAlarmSound,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_up),
                      const SizedBox(width: 12),
                      const Text('Volume'),
                      const Spacer(),
                      Text('${_settings.volume}%'),
                    ],
                  ),
                  Slider(
                    value: _settings.volume.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          volume: value.round(),
                        );
                      });
                    },
                    onChangeEnd: (_) => _saveSettings(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: SwitchListTile(
              title: const Text('Vibrate'),
              subtitle: const Text('Vibrate when alarm rings'),
              value: _settings.vibrate,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(vibrate: value);
                });
                _saveSettings();
              },
              secondary: const Icon(Icons.vibration),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer),
                      const SizedBox(width: 12),
                      Text('Reminder: ${_settings.reminderMinutesBefore} min before'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _settings.reminderMinutesBefore.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${_settings.reminderMinutesBefore} min',
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          reminderMinutesBefore: value.round(),
                        );
                      });
                    },
                    onChangeEnd: (_) => _saveSettings(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
