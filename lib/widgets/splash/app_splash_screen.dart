import 'dart:async';
import 'package:flutter/material.dart';

/// Pantalla de carga interactiva y explicativa con estados en tiempo real,
/// consejos de productividad y efectos visuales de aura.
class AppSplashScreen extends StatefulWidget {
  final String? customMessage;

  const AppSplashScreen({super.key, this.customMessage});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _currentStepIndex = 0;
  int _currentTipIndex = 0;
  Timer? _stepTimer;
  Timer? _tipTimer;

  static const List<String> _loadingSteps = [
    'Iniciando motor seguro...',
    'Verificando cifrado militar AES-256...',
    'Cargando tareas, notas y finanzas...',
    'Optimizando espacio de trabajo...',
    '¡Todo listo para ti!',
  ];

  static const List<String> _productivityTips = [
    '💡 Consejo: Divide grandes proyectos en tareas de 25 minutos con el temporizador Pomodoro.',
    '🔒 Privacidad: Tus notas y gastos están cifrados con AES-256. Solo tú tienes la clave.',
    '⚡ Offline-First: Puedes usar AuraList sin internet; se sincronizará automáticamente al conectar.',
    '🎯 Enfoque: Marca tus prioridades del día en la pestaña "Hoy" para reducir el estrés.',
    '💰 Finanzas: Vincula gastos a tus tareas para controlar el presupuesto de cada objetivo.',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ciclo de pasos de inicialización
    _stepTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _loadingSteps.length - 1) {
        setState(() => _currentStepIndex++);
      }
    });

    // Ciclo interactivo de consejos
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _productivityTips.length;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stepTimer?.cancel();
    _tipTimer?.cancel();
    super.dispose();
  }

  void _nextTip() {
    setState(() {
      _currentTipIndex = (_currentTipIndex + 1) % _productivityTips.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (_currentStepIndex + 1) / _loadingSteps.length;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo animado con efecto pulso de Aura
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => CircleAvatar(
                          backgroundColor: colorScheme.primary,
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Nombre de la App
                Text(
                  'AuraList',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                        letterSpacing: 0.8,
                      ),
                ),

                const SizedBox(height: 8),

                // Badge de seguridad
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'Cifrado Zero-Knowledge AES-256',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Barra de progreso interactiva
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            widget.customMessage ?? _loadingSteps[_currentStepIndex],
                            key: ValueKey<int>(_currentStepIndex),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: progress),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Tarjeta interactiva de Consejos
                GestureDetector(
                  onTap: _nextTip,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _productivityTips[_currentTipIndex],
                            key: ValueKey<int>(_currentTipIndex),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Toca para ver otro consejo',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.primary.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.touch_app_outlined, size: 12, color: colorScheme.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
