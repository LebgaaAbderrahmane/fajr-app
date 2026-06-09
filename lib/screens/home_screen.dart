import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../services/alarm_service.dart';
import '../services/settings_service.dart';
import 'location_setup_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final PrayerService _prayerService = PrayerService();
  final AlarmService _alarmService = AlarmService();
  final SettingsService _settingsService = SettingsService();

  LocationData? _location;
  PrayerTimeData? _fajrTime;
  String? _timeUntilFajr;
  bool _isLoading = true;
  bool _alarmScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final location = await _locationService.resolveLocation();
    if (location != null) {
      _prayerService.calculatePrayerTimes(location);
      final fajr = _prayerService.getFajrTime();
      final timeUntil = _prayerService.timeUntilFajr();

      setState(() {
        _location = location;
        _fajrTime = fajr;
        _timeUntilFajr = timeUntil != null
            ? _prayerService.formatDuration(timeUntil)
            : null;
        _isLoading = false;
      });

      _scheduleAlarmIfNeeded();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scheduleAlarmIfNeeded() async {
    if (_fajrTime == null) return;

    final settings = await _settingsService.getSettings();
    if (!settings.isEnabled) {
      await _alarmService.cancelAlarm();
      setState(() => _alarmScheduled = false);
      return;
    }

    await _alarmService.scheduleAlarm(
      fajrTime: _fajrTime!.time,
      settings: settings,
    );
    setState(() => _alarmScheduled = true);
  }

  void _navigateToLocationSetup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationSetupScreen()),
    );
    _loadData();
  }

  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    _scheduleAlarmIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fajr Alarm'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _location == null
              ? _buildNoLocation()
              : _buildMainContent(),
    );
  }

  Widget _buildNoLocation() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Please set your location to calculate accurate Fajr prayer times.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _navigateToLocationSetup,
              icon: const Icon(Icons.location_on),
              label: const Text('Set Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Today's Fajr Time",
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _fajrTime?.formattedTime ?? '--:--',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    if (_timeUntilFajr != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'In $_timeUntilFajr',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.indigo),
                title: const Text('Location'),
                subtitle: Text(_location!.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: _navigateToLocationSetup,
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: SwitchListTile(
                title: const Text('Fajr Alarm'),
                subtitle: Text(
                  _alarmScheduled
                      ? 'Scheduled — alarm will ring before Fajr'
                      : 'Alarm is disabled',
                ),
                value: _alarmScheduled,
                onChanged: (value) async {
                  final settings = await _settingsService.getSettings();
                  await _settingsService.saveSettings(
                    settings.copyWith(isEnabled: value),
                  );
                  _scheduleAlarmIfNeeded();
                },
                secondary: Icon(
                  _alarmScheduled ? Icons.alarm : Icons.alarm_off,
                  color: _alarmScheduled ? Colors.indigo : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'All Prayer Times',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            ..._prayerService.getAllPrayerTimes().map(
                  (prayer) => Card(
                    child: ListTile(
                      leading: Icon(
                        prayer.prayerName == 'Fajr'
                            ? Icons.nightlight_round
                            : prayer.prayerName == 'Sunrise'
                                ? Icons.wb_sunny
                                : prayer.prayerName == 'Dhuhr'
                                    ? Icons.wb_sunny_outlined
                                    : prayer.prayerName == 'Asr'
                                        ? Icons.wb_cloudy
                                        : prayer.prayerName == 'Maghrib'
                                            ? Icons.wb_twilight
                                            : Icons.nightlight_outlined,
                        color: prayer.prayerName == 'Fajr'
                            ? Colors.indigo
                            : Colors.grey,
                      ),
                      title: Text(prayer.prayerName),
                      trailing: Text(
                        prayer.formattedTime,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: prayer.prayerName == 'Fajr'
                              ? Colors.indigo
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
