import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? cityName;
  final String? countryName;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.cityName,
    this.countryName,
  });

  String get displayName {
    if (cityName != null && countryName != null) {
      return '$cityName, $countryName';
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}

class LocationService {
  static const String _latKey = 'user_latitude';
  static const String _lonKey = 'user_longitude';
  static const String _cityKey = 'user_city';
  static const String _countryKey = 'user_country';
  static const String _useAutoLocationKey = 'use_auto_location';

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<LocationData?> getCurrentLocation() async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String? city;
      String? country;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          city = placemarks.first.locality;
          country = placemarks.first.country;
        }
      } catch (_) {}

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: city,
        countryName: country,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveLocation(LocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, location.latitude);
    await prefs.setDouble(_lonKey, location.longitude);
    await prefs.setString(_cityKey, location.cityName ?? '');
    await prefs.setString(_countryKey, location.countryName ?? '');
  }

  Future<void> setUseAutoLocation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useAutoLocationKey, value);
  }

  Future<bool> getUseAutoLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useAutoLocationKey) ?? true;
  }

  Future<LocationData?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lon = prefs.getDouble(_lonKey);
    if (lat == null || lon == null) return null;

    return LocationData(
      latitude: lat,
      longitude: lon,
      cityName: prefs.getString(_cityKey),
      countryName: prefs.getString(_countryKey),
    );
  }

  Future<LocationData?> resolveLocation() async {
    final useAuto = await getUseAutoLocation();
    if (useAuto) {
      final auto = await getCurrentLocation();
      if (auto != null) {
        await saveLocation(auto);
        return auto;
      }
    }
    return getSavedLocation();
  }
}
