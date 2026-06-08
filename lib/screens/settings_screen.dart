import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/alarm_service.dart';
import 'alarm_ringing_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final AlarmService _alarmService = AlarmService();
  AlarmSettings _settings = const AlarmSettings();
  bool _isLoading = true;
  bool _isTestingAlarm = false;
  String? _customSoundName;

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
    String? customName;
    if (settings.alarmSoundPath.startsWith('content://')) {
      customName = await _alarmService.getDisplayName(settings.alarmSoundPath);
    }
    setState(() {
      _settings = settings;
      _customSoundName = customName;
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
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select Alarm Sound',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
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
                              _settings = _settings.copyWith(
                                alarmSoundPath: sound['path']!,
                              );
                            });
                            _saveSettings();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.folder_open),
                        title: const Text('Choose from phone'),
                        subtitle: const Text('Pick an audio file from your device'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _pickCustomSound();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickCustomSound() async {
    final path = await _alarmService.pickAudioFile();
    if (path != null && mounted) {
      final name = await _alarmService.getDisplayName(path);
      setState(() {
        _settings = _settings.copyWith(alarmSoundPath: path);
        _customSoundName = name;
      });
      _saveSettings();
    }
  }

  String _getSoundDisplayName(String path) {
    if (path.startsWith('content://') || path.startsWith('/')) {
      if (_customSoundName != null) {
        final name = _customSoundName!;
        return name.length > 30 ? '${name.substring(0, 27)}...' : name;
      }
      return 'Custom audio file';
    }
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

  void _testAlarm() async {
    setState(() => _isTestingAlarm = true);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmRingingScreen(
          settings: _settings,
          testMode: true,
        ),
      ),
    );

    setState(() => _isTestingAlarm = false);
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

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isTestingAlarm ? null : _testAlarm,
              icon: _isTestingAlarm
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isTestingAlarm ? 'Playing...' : 'Test Alarm',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
