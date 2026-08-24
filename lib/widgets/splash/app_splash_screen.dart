import 'dart:async';
import 'package:flutter/material.dart';

/// Pantalla de carga interactiva, alegre, motivadora y explicativa
/// con pasos en tiempo real, gamificación de energía y frases inspiradoras.
class AppSplashScreen extends StatefulWidget {
  final String? customMessage;

  const AppSplashScreen({super.key, this.customMessage});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _sparkleController;

  int _currentStepIndex = 0;
  int _currentQuoteIndex = 0;
  int _energyClicks = 0;
  Timer? _stepTimer;
  Timer? _quoteTimer;

  static const List<String> _loadingSteps = [
    '✨ Despertando el motor inteligente de AuraList...',
    '🔐 Blindando tus datos con cifrado militar AES-256...',
    '☕ Preparando tu café mental y tus finanzas...',
    '🎯 Sincronizando tus súper poderes de enfoque...',
    '🎉 ¡Despegamos! Todo listo para triunfar.',
  ];

  static const List<Map<String, String>> _motivationalQuotes = [
    {
      'quote': 'El secreto para avanzar es simplemente comenzar.',
      'author': 'Mark Twain',
      'emoji': '🚀',
    },
    {
      'quote': 'Tu mente es para tener grandes ideas, no para guardarlas con estrés.',
      'author': 'David Allen',
      'emoji': '🧠',
    },
    {
      'quote': 'Tus notas y finanzas están 100% protegidas y cifradas. Tu privacidad es sagrada.',
      'author': 'AuraList Security',
      'emoji': '🛡️',
    },
    {
      'quote': '25 minutos de enfoque puro con Pomodoro valen más que horas disperso.',
      'author': 'Método Francesco Cirillo',
      'emoji': '🍅',
    },
    {
      'quote': 'La disciplina es el puente que conecta tus sueños con tus logros.',
      'author': 'Jim Rohn',
      'emoji': '💎',
    },
    {
      'quote': 'Pequeños pasos constantes generan victorias gigantescas.',
      'author': 'Kaikaku',
      'emoji': '🔥',
    },
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 13) {
      return '☀️ ¡Buenos días, titán!';
    } else if (hour >= 13 && hour < 20) {
      return '⚡ ¡A por una tarde imparable!';
    } else {
      return '🌙 Cerrando el día con broche de oro';
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutBack),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Ciclo de pasos explicativos
    _stepTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _loadingSteps.length - 1) {
        setState(() => _currentStepIndex++);
      }
    });

    // Ciclo automático de frases inspiradoras
    _quoteTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _currentQuoteIndex = (_currentQuoteIndex + 1) % _motivationalQuotes.length;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sparkleController.dispose();
    _stepTimer?.cancel();
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _tapEnergy() {
    _sparkleController.forward(from: 0.0);
    setState(() {
      _energyClicks++;
      _currentQuoteIndex = (_currentQuoteIndex + 1) % _motivationalQuotes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (_currentStepIndex + 1) / _loadingSteps.length;
    final activeQuote = _motivationalQuotes[_currentQuoteIndex];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              const Color(0xFF1E1B4B).withValues(alpha: 0.95), // Deep Indigo
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Saludo alegre y motivador
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Logo animado con halo luminoso
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                              blurRadius: 35,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                              blurRadius: 25,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(55),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => CircleAvatar(
                            radius: 45,
                            backgroundColor: colorScheme.primary,
                            child: const Icon(Icons.rocket_launch, color: Colors.white, size: 44),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Nombre con estilo tipográfico
                Text(
                  'AuraList',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                ),

                const SizedBox(height: 8),

                // Pill Badge de Cifrado Militar E2EE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: Color(0xFF4ADE80)),
                      SizedBox(width: 6),
                      Text(
                        '100% Privado • Cifrado AES-256 E2EE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Barra de Progreso y Estados en tiempo real
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                widget.customMessage ?? _loadingSteps[_currentStepIndex],
                                key: ValueKey<int>(_currentStepIndex),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE2E8F0),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(begin: 0, end: progress),
                          builder: (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Tarjeta Interactiva con Frase Inspiradora & Botón de Energía
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _tapEnergy,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF312E81).withValues(alpha: 0.6),
                            const Color(0xFF1E1B4B).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF818CF8).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                activeQuote['emoji'] ?? '💡',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeQuote['author'] ?? 'Inspiración',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFA5B4FC),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (_energyClicks > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '⚡ x$_energyClicks',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              '"${activeQuote['quote']}"',
                              key: ValueKey<int>(_currentQuoteIndex),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE2E8F0),
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Toca aquí para recargar energía positiva',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF818CF8),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.touch_app, size: 14, color: Color(0xFF818CF8)),
                            ],
                          ),
                        ],
                      ),
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
