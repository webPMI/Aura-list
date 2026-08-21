import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PomodoroMode {
  focus(durationMinutes: 25, label: 'Enfoque', icon: Icons.timer_outlined, color: Colors.deepPurple),
  shortBreak(durationMinutes: 5, label: 'Descanso', icon: Icons.coffee_outlined, color: Colors.teal),
  longBreak(durationMinutes: 15, label: 'Descanso Largo', icon: Icons.spa_outlined, color: Colors.indigo);

  final int durationMinutes;
  final String label;
  final IconData icon;
  final MaterialColor color;

  const PomodoroMode({
    required this.durationMinutes,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class PomodoroTimerCard extends StatefulWidget {
  const PomodoroTimerCard({super.key});

  @override
  State<PomodoroTimerCard> createState() => _PomodoroTimerCardState();
}

class _PomodoroTimerCardState extends State<PomodoroTimerCard>
    with SingleTickerProviderStateMixin {
  PomodoroMode _mode = PomodoroMode.focus;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  int _completedSessions = 0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _mode.durationMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _switchMode(PomodoroMode mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _remainingSeconds = mode.durationMinutes * 60;
      _isRunning = false;
    });
    HapticFeedback.selectionClick();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    HapticFeedback.mediumImpact();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _mode.durationMinutes * 60;
      _isRunning = false;
    });
  }

  void _onTimerComplete() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRunning = false;
      if (_mode == PomodoroMode.focus) {
        _completedSessions++;
        // Auto sugerir descanso
        if (_completedSessions % 4 == 0) {
          _mode = PomodoroMode.longBreak;
        } else {
          _mode = PomodoroMode.shortBreak;
        }
        _remainingSeconds = _mode.durationMinutes * 60;
      } else {
        _mode = PomodoroMode.focus;
        _remainingSeconds = _mode.durationMinutes * 60;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                _mode == PomodoroMode.focus
                    ? '¡Descanso terminado! Momento de enfocarse.'
                    : '¡Sesión de enfoque completada! Tómate un respiro.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: _mode.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final totalSeconds = _mode.durationMinutes * 60;
    return 1.0 - (_remainingSeconds / totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = _mode.color;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: _isRunning ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _isRunning
              ? activeColor.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: _isRunning ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Cabecera compacta con toggle para expandir
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_mode.icon, color: activeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Temporizador Pomodoro',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (_completedSessions > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '🍅 $_completedSessions',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${_mode.label} · $_formattedTime restantes',
                          style: TextStyle(
                            fontSize: 12,
                            color: activeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón Play / Pause rápido en la barra
                  IconButton.filledTonal(
                    iconSize: 20,
                    style: IconButton.styleFrom(
                      backgroundColor: activeColor.withValues(alpha: 0.15),
                      foregroundColor: activeColor,
                    ),
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    onPressed: _toggleTimer,
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),

            // Contenido expandido con reloj circular y selector de modos
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Selector de modos
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: PomodoroMode.values.map((mode) {
                    final isSelected = mode == _mode;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('${mode.label} (${mode.durationMinutes}m)'),
                        avatar: Icon(mode.icon, size: 16),
                        selected: isSelected,
                        selectedColor: mode.color.withValues(alpha: 0.2),
                        onSelected: (_) => _switchMode(mode),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Reloj circular interactivo
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _mode.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: activeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Controles principales
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reiniciar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _toggleTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      _isRunning ? 'Pausar' : 'Iniciar',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
