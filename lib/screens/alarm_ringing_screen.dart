import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/alarm_service.dart';
import '../services/settings_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  final AlarmSettings settings;
  final bool testMode;

  const AlarmRingingScreen({
    super.key,
    required this.settings,
    this.testMode = false,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  final AlarmService _alarmService = AlarmService();
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  bool _isDismissing = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (!widget.testMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    if (_hasStarted) return;
    _hasStarted = true;
    await _alarmService.playAlarm(widget.settings, testMode: widget.testMode);
  }

  @override
  void dispose() {
    if (widget.testMode) {
      _alarmService.stopAlarm(testMode: true);
    }
    _animController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _dismissAlarm() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    await _alarmService.stopAlarm(testMode: widget.testMode);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final isTestMode = widget.testMode;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.indigo.withValues(alpha: 0.3),
                      border: Border.all(
                        color: Colors.indigo.withValues(alpha: 0.6),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.alarm,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  '$hour:$minute',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                Text(
                  period,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Fajr Prayer Time',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),

                const Spacer(flex: 2),

                if (isTestMode)
                  if (_isDismissing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _dismissAlarm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stop, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Stop Alarm',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                if (!isTestMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Alarm will stop when the adhan ends.\nYou can also stop it from the notification.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
