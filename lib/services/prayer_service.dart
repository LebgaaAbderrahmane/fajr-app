import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'location_service.dart';

class PrayerTimeData {
  final String prayerName;
  final DateTime time;

  const PrayerTimeData({required this.prayerName, required this.time});

  String get formattedTime => DateFormat('hh:mm a').format(time);
}

class PrayerService {
  PrayerTimes? _prayerTimes;

  PrayerTimes? get prayerTimes => _prayerTimes;

  PrayerTimes? calculatePrayerTimes(LocationData location) {
    final coordinates = Coordinates(location.latitude, location.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    _prayerTimes = PrayerTimes.today(coordinates, params);
    return _prayerTimes;
  }

  PrayerTimeData? getFajrTime() {
    if (_prayerTimes == null) return null;
    return PrayerTimeData(
      prayerName: 'Fajr',
      time: _prayerTimes!.fajr,
    );
  }

  List<PrayerTimeData> getAllPrayerTimes() {
    if (_prayerTimes == null) return [];
    return [
      PrayerTimeData(prayerName: 'Fajr', time: _prayerTimes!.fajr),
      PrayerTimeData(prayerName: 'Sunrise', time: _prayerTimes!.sunrise),
      PrayerTimeData(prayerName: 'Dhuhr', time: _prayerTimes!.dhuhr),
      PrayerTimeData(prayerName: 'Asr', time: _prayerTimes!.asr),
      PrayerTimeData(prayerName: 'Maghrib', time: _prayerTimes!.maghrib),
      PrayerTimeData(prayerName: 'Isha', time: _prayerTimes!.isha),
    ];
  }

  Duration? timeUntilFajr() {
    if (_prayerTimes == null) return null;
    final now = DateTime.now();
    final fajr = _prayerTimes!.fajr;
    if (fajr.isAfter(now)) {
      return fajr.difference(now);
    } else {
      return fajr.add(const Duration(days: 1)).difference(now);
    }
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
