import 'dart:math';
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
  final TextEditingController _answerController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  bool _isDismissing = false;
  bool _hasStarted = false;
  bool _challengeVerified = false;
  String _challengeText = '';
  int _challengeAnswer = 0;
  String? _challengeError;
  int _wrongAttempts = 0;

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

    if (widget.settings.hardMode) {
      _generateChallenge();
    } else {
      _challengeVerified = true;
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startAlarm();
  }

  void _generateChallenge() {
    final random = Random();
    final ops = ['+', '-', '×'];
    final op = ops[random.nextInt(ops.length)];

    int a, b, answer;
    switch (op) {
      case '+':
        a = random.nextInt(20) + 5;
        b = random.nextInt(20) + 5;
        answer = a + b;
        break;
      case '-':
        a = random.nextInt(20) + 10;
        b = random.nextInt(a) + 1;
        answer = a - b;
        break;
      case '×':
        a = random.nextInt(12) + 2;
        b = random.nextInt(12) + 2;
        answer = a * b;
        break;
      default:
        a = 1;
        b = 1;
        answer = 2;
    }

    setState(() {
      _challengeText = '$a $op $b = ?';
      _challengeAnswer = answer;
      _challengeError = null;
    });
  }

  Future<void> _startAlarm() async {
    if (_hasStarted) return;
    _hasStarted = true;
    await _alarmService.playAlarm(widget.settings);
  }

  @override
  void dispose() {
    if (widget.testMode) {
      _alarmService.stopAlarm();
    }
    _animController.dispose();
    _answerController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _verifyAnswer() {
    final input = int.tryParse(_answerController.text.trim());
    if (input == _challengeAnswer) {
      setState(() {
        _challengeVerified = true;
        _challengeError = null;
      });
    } else {
      setState(() {
        _wrongAttempts++;
        _challengeError = 'Wrong answer. Try again.';
        _answerController.clear();
      });
      _generateChallenge();
    }
  }

  void _dismissAlarm() async {
    if (_isDismissing) return;

    if (widget.settings.hardMode && !_challengeVerified) {
      _verifyAnswer();
      return;
    }

    setState(() => _isDismissing = true);
    await _alarmService.stopAlarm();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _snoozeAlarm() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    await _alarmService.stopAlarm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snoozed for 10 minutes')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final isHardMode = widget.settings.hardMode;
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

                if (isHardMode && isTestMode) ...[
                  const SizedBox(height: 30),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              color: Colors.orange.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Solve to dismiss',
                              style: TextStyle(
                                color: Colors.orange.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _challengeText,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _answerController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Your answer',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _dismissAlarm(),
                          ),
                        ),
                        if (_challengeError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _challengeError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (_wrongAttempts > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$_wrongAttempts wrong attempt${_wrongAttempts > 1 ? "s" : ""}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

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
                      child: Column(
                        children: [
                          SizedBox(
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isHardMode && !_challengeVerified
                                        ? Icons.check
                                        : Icons.stop,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isHardMode && !_challengeVerified
                                        ? 'Submit Answer'
                                        : 'Stop Alarm',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _snoozeAlarm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.snooze, size: 28),
                                  SizedBox(width: 12),
                                  Text(
                                    'Snooze 10 min',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
