# Guías Celestiales - Sistema de Onboarding

## Descripción General

El sistema de onboarding de Guías Celestiales introduce a los usuarios nuevos al concepto de los guías y les ayuda a elegir su primer guía de manera informada y mágica.

## Arquitectura

### Componentes Principales

#### 1. `guide_onboarding_provider.dart`
**Ubicación:** `lib/features/guides/providers/guide_onboarding_provider.dart`

**Responsabilidad:** Gestionar el estado de onboarding (si el usuario ha visto la introducción).

**Providers:**
- `guideOnboardingServiceProvider` - Servicio para manejar persistencia en SharedPreferences
- `shouldShowGuideIntroProvider` - FutureProvider que determina si mostrar el intro (true si no lo ha visto y no tiene guía)

**Métodos del Servicio:**
```dart
Future<bool> hasSeenGuideIntro() // Verifica si ya vio el intro
Future<void> markIntroAsSeen()   // Marca como visto
Future<void> resetIntro()        // Reset para testing
```

#### 2. `guide_intro_modal.dart`
**Ubicación:** `lib/features/guides/widgets/guide_intro_modal.dart`

**Responsabilidad:** Modal de introducción con 3 páginas swipeable que explican el concepto de guías.

**Función Principal:**
```dart
void showGuideIntroModal(BuildContext context, WidgetRef ref)
```

**Páginas del Onboarding:**

1. **Card 1: "Tu Guardián Celestial"**
   - Icono de estrella con animación de brillo pulsante
   - Explica que los guías son compañeros, no jueces
   - Botón "Continuar" para pasar a la siguiente página

2. **Card 2: "Cada Guía, Un Poder"**
   - Muestra 4 ejemplos de afinidades con iconos y colores:
     - Prioridad (naranja) - Aethel
     - Descanso (morado) - Luna-Vacía
     - Creatividad (rosa) - Eris-Núcleo
     - Hábitos (verde) - Gea-Métrica
   - Botón "Continuar"

3. **Card 3: "Bendiciones Activas"**
   - Ejemplo visual de una bendición
   - Explica que las bendiciones nunca castigan, solo refuerzan
   - Nota informativa: "Puedes cambiar de guía en cualquier momento"
   - Botón principal: "Elegir mi Guía" → Abre el selector

**Características Visuales:**
- Fondo con gradiente oscuro
- Animaciones suaves (fade in, parallax)
- Haptic feedback al cambiar de página
- Indicadores de página (dots) en la parte inferior
- Botón "Saltar" discreto en la esquina superior derecha

#### 3. `featured_guide_card.dart`
**Ubicación:** `lib/features/guides/widgets/featured_guide_card.dart`

**Responsabilidad:** Widget reutilizable para destacar un guía con diseño ceremonial.

**Características:**
- Avatar grande (120px) con animación de entrada
- Nombre y título del guía
- Badge de afinidad con icono
- Sentencia de poder (máx 3 líneas)
- Botón opcional "Elegir este guía"
- Fondo con gradiente del color del guía

**Uso:**
```dart
FeaturedGuideCard(
  guide: guideInstance,
  onSelect: () { /* acción */ },
  showSelectButton: true,
)
```

## Flujo de Usuario

### Primera Vez

1. Usuario abre AuraList por primera vez
2. Ve el WelcomeScreen estándar
3. Continúa a MainScaffold
4. MainScaffold detecta que no ha visto el intro y no tiene guía
5. Después de 500ms, muestra automáticamente `showGuideIntroModal()`
6. Usuario navega por las 3 páginas del intro
7. Al llegar a la página 3, toca "Elegir mi Guía"
8. Se cierra el modal y se abre `showGuideSelectorSheet()`
9. Usuario elige su primer guía
10. El sistema marca el intro como visto

### Acceso Posterior al Info

1. Usuario va a Configuración → "Guía celestial" → Toca el icono (i)
2. O desde el selector de guías, toca el icono de info en el header
3. Se abre el mismo modal de introducción
4. Puede navegar libremente o cerrar cuando quiera

## Integración en el Código

### En `main_scaffold.dart`

```dart
class _MainScaffoldState extends ConsumerState<MainScaffold> {
  bool _hasCheckedIntro = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowGuideIntro();
    });
  }

  Future<void> _checkAndShowGuideIntro() async {
    if (_hasCheckedIntro || !mounted) return;
    _hasCheckedIntro = true;

    final shouldShow = await ref.read(shouldShowGuideIntroProvider.future);

    if (shouldShow && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        showGuideIntroModal(context, ref);
      }
    }
  }
  // ...
}
```

### En `guide_selector_sheet.dart`

```dart
// En el header del selector
IconButton(
  icon: const Icon(Icons.info_outline),
  tooltip: '¿Qué es un Guía Celestial?',
  onPressed: () {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showGuideIntroModal(context, ref);
      }
    });
  },
)
```

## Persistencia

**Clave de SharedPreferences:** `has_seen_guide_intro`

**Tipo:** `bool`

**Valores:**
- `null` o `false` → No ha visto el intro
- `true` → Ya vio el intro

## Testing

### Para resetear el onboarding durante desarrollo:

```dart
// Desde cualquier widget con ref
await ref.read(guideOnboardingServiceProvider).resetIntro();
```

### Para forzar mostrar el intro:

```dart
// Resetear preferencia
await ref.read(guideOnboardingServiceProvider).resetIntro();

// Mostrar modal
if (context.mounted) {
  showGuideIntroModal(context, ref);
}
```

## Filosofía de Diseño

### Tono
- **Solemne pero accesible:** Como la Biblia de Estilo de AuraList
- **Mágico, no aburrido:** Animaciones sutiles, colores celestiales
- **No técnico:** Evitar jerga ("provider", "widget", etc.)
- **Opcional:** El usuario puede saltar en cualquier momento

### Colores
- **Fondo:** Gradiente oscuro con transparencia
- **Texto:** Claro, legible, con diferentes niveles de opacidad
- **Acentos:** Dorados/celestiales, colores primarios del tema
- **Iconos:** Colores de afinidad de cada guía

### Animaciones
- **Brillo pulsante:** En el icono de estrella de la Card 1
- **Fade in:** Elementos aparecen gradualmente
- **Scale:** Avatar del FeaturedGuideCard crece al aparecer
- **Transiciones suaves:** PageView con curves.easeInOut

## Mantenimiento

### Agregar una nueva página al onboarding

1. Crear una nueva clase `_IntroPageX` en `guide_intro_modal.dart`
2. Agregar el widget al PageView
3. Actualizar el contador de dots (actualmente 3)

### Modificar contenido

Todo el contenido está hardcoded en español en los widgets. Para modificar:
- Títulos: Buscar "Tu Guardián Celestial", "Cada Guía, Un Poder", etc.
- Ejemplos de afinidades: Modificar los widgets `_AffinityExample` en `_IntroPage2`
- Colores: Ajustar los valores hexadecimales en cada `_AffinityExample`

### Cambiar timing

```dart
// Delay antes de mostrar el modal (main_scaffold.dart)
await Future.delayed(const Duration(milliseconds: 500));

// Duración de animaciones (guide_intro_modal.dart)
duration: const Duration(milliseconds: 400), // PageView
duration: const Duration(seconds: 2),        // Shimmer
```

## Dependencias

- `flutter_riverpod` - State management
- `shared_preferences` - Persistencia local
- `flutter/services` - Haptic feedback

## Exports

Todos los componentes están exportados en `lib/features/guides/guides.dart`:

```dart
export 'package:checklist_app/features/guides/providers/guide_onboarding_provider.dart';
export 'package:checklist_app/features/guides/widgets/guide_intro_modal.dart';
export 'package:checklist_app/features/guides/widgets/featured_guide_card.dart';
```

## Mejoras Futuras

### Posibles Extensiones

1. **Onboarding Progresivo:**
   - Mostrar tips contextuales la primera vez que completa una tarea
   - Tooltip sobre bendiciones cuando se activan por primera vez

2. **Personalización:**
   - Permitir al usuario saltar directamente a un guía recomendado según sus respuestas
   - Quiz de personalidad para sugerir un guía inicial

3. **Animaciones Avanzadas:**
   - Lottie animations para iconos celestiales
   - Parallax scrolling en el fondo
   - Particle effects en transiciones

4. **Accesibilidad:**
   - Soporte para lectores de pantalla
   - Modo reducido de movimiento
   - Alto contraste

5. **Analytics:**
   - Trackear qué usuarios completan el onboarding
   - Qué guías se eligen más frecuentemente después del intro
   - Cuántos usuarios saltan vs. completan
