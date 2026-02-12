import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/features/guides/providers/guide_onboarding_provider.dart';
import 'package:checklist_app/features/guides/widgets/guide_selector_sheet.dart';

/// Muestra el modal de introducción a los Guías Celestiales.
/// Este es el onboarding que explica qué son los guías y por qué elegir uno.
void showGuideIntroModal(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _GuideIntroModal(),
  ).then((_) {
    // Marcar como visto cuando se cierra el modal
    ref.read(guideOnboardingServiceProvider).markIntroAsSeen();
  });
}

class _GuideIntroModal extends StatefulWidget {
  const _GuideIntroModal();

  @override
  State<_GuideIntroModal> createState() => _GuideIntroModalState();
}

class _GuideIntroModalState extends State<_GuideIntroModal>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      HapticFeedback.lightImpact();
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  void _openSelector(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(); // Cerrar el intro modal
    // Esperar un frame antes de abrir el selector
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showGuideSelectorSheet(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.85;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle visual
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Botón Saltar (discreto, arriba derecha)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                child: const Text('Saltar'),
              ),
            ),
          ),

          // PageView con las 3 cards
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                HapticFeedback.selectionClick();
              },
              children: [
                _IntroPage1(onNext: _nextPage),
                _IntroPage2(onNext: _nextPage),
                _IntroPage3(onChoose: () => _openSelector(context)),
              ],
            ),
          ),

          // Indicadores de página (dots)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card 1: "Tu Guardián Celestial"
class _IntroPage1 extends StatefulWidget {
  const _IntroPage1({required this.onNext});

  final VoidCallback onNext;

  @override
  State<_IntroPage1> createState() => _IntroPage1State();
}

class _IntroPage1State extends State<_IntroPage1>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          // Icono celestial con animación de brillo
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(
                        alpha: 0.3 + (_shimmerController.value * 0.2),
                      ),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.2 + (_shimmerController.value * 0.3),
                      ),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(
                    alpha: 0.7 + (_shimmerController.value * 0.3),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),

          // Título
          Text(
            'Tu Guardián Celestial',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Descripción
          Text(
            'Cada guía representa una fuerza cósmica que te acompaña en tu día a día. Son compañeros, no jueces.',
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Decoración adicional
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_people,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Los guías están aquí para apoyarte, no para presionarte. Cada uno tiene su propia energía y poder.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Botón siguiente
          FilledButton.tonalIcon(
            onPressed: widget.onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card 2: "Afinidades"
class _IntroPage2 extends StatelessWidget {
  const _IntroPage2({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          // Título
          Text(
            'Cada Guía, Un Poder',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Descripción
          Text(
            'Prioridad, Descanso, Creatividad, Hábitos... Elige el guía que resuene con tu momento actual.',
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Ejemplos de afinidades con iconos y colores
          _AffinityExample(
            icon: Icons.flash_on,
            affinity: 'Prioridad',
            color: const Color(0xFFE65100),
            example: 'Aethel para días de acción',
          ),
          const SizedBox(height: 16),
          _AffinityExample(
            icon: Icons.nightlight_round,
            affinity: 'Descanso',
            color: const Color(0xFF4A148C),
            example: 'Luna-Vacía para calma',
          ),
          const SizedBox(height: 16),
          _AffinityExample(
            icon: Icons.auto_fix_high,
            affinity: 'Creatividad',
            color: const Color(0xFFC2185B),
            example: 'Eris-Núcleo para ideas',
          ),
          const SizedBox(height: 16),
          _AffinityExample(
            icon: Icons.spa,
            affinity: 'Hábitos',
            color: const Color(0xFF388E3C),
            example: 'Gea-Métrica para constancia',
          ),
          const SizedBox(height: 40),

          // Botón siguiente
          FilledButton.tonalIcon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AffinityExample extends StatelessWidget {
  const _AffinityExample({
    required this.icon,
    required this.affinity,
    required this.color,
    required this.example,
  });

  final IconData icon;
  final String affinity;
  final Color color;
  final String example;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  affinity,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  example,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card 3: "Bendiciones"
class _IntroPage3 extends StatelessWidget {
  const _IntroPage3({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          // Título
          Text(
            'Bendiciones Activas',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Descripción
          Text(
            'Tu guía otorga poderes sutiles que cambian la experiencia de la app. Nunca castigan; solo refuerzan.',
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Ejemplo visual de una bendición
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.tertiary.withValues(alpha: 0.2),
                  theme.colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ejemplo de Bendición',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '"La gracia de la acción inmediata ilumina tus primeras tareas"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nota adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Puedes cambiar de guía en cualquier momento desde Configuración.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Botón final: Elegir mi Guía
          FilledButton.icon(
            onPressed: onChoose,
            icon: const Icon(Icons.explore),
            label: const Text('Elegir mi Guía'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
