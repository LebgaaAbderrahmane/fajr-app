import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  bool _useAutoLocation = true;
  LocationData? _currentLocation;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoading = true);
    final useAuto = await _locationService.getUseAutoLocation();
    final saved = await _locationService.getSavedLocation();
    setState(() {
      _useAutoLocation = useAuto;
      _currentLocation = saved;
      if (saved != null && !useAuto) {
        _latController.text = saved.latitude.toString();
        _lonController.text = saved.longitude.toString();
        _cityController.text = saved.cityName ?? '';
      }
      _isLoading = false;
    });
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      await _locationService.saveLocation(location);
      await _locationService.setUseAutoLocation(true);
      setState(() {
        _currentLocation = location;
        _useAutoLocation = true;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location detected: ${location.displayName}')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Could not detect location. Please check permissions.';
      });
    }
  }

  Future<void> _saveManualLocation() async {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);

    if (lat == null || lon == null) {
      setState(() => _error = 'Please enter valid coordinates');
      return;
    }

    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      setState(() => _error = 'Coordinates out of range');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final location = LocationData(
      latitude: lat,
      longitude: lon,
      cityName: _cityController.text.isNotEmpty ? _cityController.text : null,
    );

    await _locationService.saveLocation(location);
    await _locationService.setUseAutoLocation(false);
    setState(() {
      _currentLocation = location;
      _useAutoLocation = false;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location saved: ${location.displayName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Setup'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 80,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Set Your Location',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We need your location to calculate accurate Fajr prayer times.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  if (_currentLocation != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentLocation!.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}, '
                              'Lon: ${_currentLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _detectLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Auto-Detect Location'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR SET MANUALLY',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _latController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: 'e.g. 36.7538',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lonController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: 'e.g. 3.0588',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City Name (optional)',
                      hintText: 'e.g. Algiers',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: _saveManualLocation,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Manual Location'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
