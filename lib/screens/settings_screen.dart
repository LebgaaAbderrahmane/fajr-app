import 'package:flutter/material.dart';
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

  final List<Map<String, String>> _alarmSounds = [
    {'name': 'Default Adhan', 'path': 'default'},
    {'name': 'Adhan - Makkah', 'path': 'makkah'},
    {'name': 'Adhan - Madinah', 'path': 'madinah'},
    {'name': 'Adhan - Al-Aqsa', 'path': 'alaqsa'},
    {'name': 'Simple Alarm', 'path': 'simple'},
  ];

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

  void _selectSound() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Alarm Sound',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ..._alarmSounds.map(
                (sound) => ListTile(
                  leading: Radio<String>(
                    value: sound['path']!,
                    groupValue: _settings.alarmSoundPath,
                    onChanged: null,
                  ),
                  title: Text(sound['name']!),
                  selected: _settings.alarmSoundPath == sound['path'],
                  onTap: () {
                    setState(() {
                      _settings = _settings.copyWith(alarmSoundPath: sound['path']!);
                    });
                    _saveSettings();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _getSoundDisplayName(String path) {
    for (var sound in _alarmSounds) {
      if (sound['path'] == path) return sound['name']!;
    }
    return path;
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
              subtitle: Text(_getSoundDisplayName(_settings.alarmSoundPath)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectSound,
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
