# Sistema de Afinidad de Guías Celestiales

## Descripción General

El Sistema de Afinidad rastrea y fortalece la relación del usuario con su Guía Celestial activo. A medida que el usuario completa tareas con un guía, su nivel de conexión aumenta, desbloqueando nuevas características y mejorando la experiencia.

## Filosofía del Guardián

- **Los niveles NUNCA bajan**: Una vez alcanzado un nivel, es permanente
- **Sin castigos**: No hay penalizaciones por inactividad
- **Celebración del progreso**: Cada avance es una victoria que se celebra
- **Respeto al ritmo del usuario**: No hay límites de tiempo ni presión

## Niveles de Afinidad

### Nivel 0: Extraño
- **Requisitos**: Estado inicial al activar un guía por primera vez
- **Descripción**: "Acabas de conocer a este guía"
- **Desbloquea**: Avatar básico

### Nivel 1: Conocido
- **Requisitos**: 5 tareas completadas + 1 día activo
- **Descripción**: "El guía comienza a conocerte"
- **Desbloquea**: Avatar coloreado (tema del guía aplicado)

### Nivel 2: Compañero
- **Requisitos**: 15 tareas completadas + 3 días activos
- **Descripción**: "Comparten experiencias juntos"
- **Desbloquea**: Sentencia de Poder visible en el dashboard

### Nivel 3: Aliado
- **Requisitos**: 30 tareas completadas + 7 días activos
- **Descripción**: "Una relación de confianza mutua"
- **Desbloquea**: Diálogos especiales y mensajes exclusivos

### Nivel 4: Vínculo
- **Requisitos**: 50 tareas completadas + 14 días activos
- **Descripción**: "Un vínculo profundo se ha formado"
- **Desbloquea**: Bendiciones mejoradas (mayor frecuencia de activación)

### Nivel 5: Alma Gemela
- **Requisitos**: 100 tareas completadas + 30 días activos
- **Descripción**: "Almas que caminan juntas"
- **Desbloquea**: Ritual de sincronización diario especial

## Arquitectura Técnica

### Modelo: GuideAffinity

```dart
class GuideAffinity {
  final String guideId;
  final int connectionLevel;        // 0-5
  final int tasksCompletedWithGuide;
  final int daysWithGuide;
  final DateTime? firstActivationDate;
  final DateTime? lastActiveDate;
}
```

### Providers

- `guideAffinityProvider(guideId)`: Family provider para obtener afinidad de un guía
- `activeGuideAffinityProvider`: Afinidad del guía activo actual
- `allAffinitiesProvider`: Mapa de todas las afinidades guardadas
- `guideAffinityNotifierProvider`: Notifier para gestionar estado

### Persistencia

Los datos de afinidad se guardan en **SharedPreferences** como JSON:
- Key pattern: `guide_affinity_{guideId}`
- Formato: JSON serializado del modelo GuideAffinity

### Integración

#### 1. Incremento de Tareas (task_tile.dart)
Al completar una tarea:
```dart
await ref.read(incrementTaskCountProvider)();
```

Esto:
1. Incrementa el contador de tareas
2. Actualiza la fecha de última actividad
3. Calcula si se alcanzó un nuevo nivel
4. Guarda en SharedPreferences
5. Retorna el nuevo nivel si hubo cambio (para mostrar celebración)

#### 2. Registro de Días Activos
Al iniciar la app o cambiar de guía:
```dart
await ref.read(checkDailyActivityProvider)();
```

Esto:
1. Verifica si ya se registró actividad hoy
2. Si no, incrementa el contador de días
3. Actualiza la fecha de última actividad
4. Recalcula el nivel
5. Guarda en SharedPreferences

#### 3. Visualización

**Indicador Compacto** (guide_selector_sheet.dart):
```dart
AffinityLevelIndicator(
  guide: guide,
  size: AffinityIndicatorSize.small,
  showLabel: false,
  showProgress: false,
)
```

**Indicador Mediano** (dashboard):
```dart
AffinityLevelIndicator(
  guide: guide,
  size: AffinityIndicatorSize.medium,
  showLabel: true,
  showProgress: true,
)
```

**Indicador Grande** (diálogo de detalles):
```dart
AffinityLevelIndicator(
  guide: guide,
  size: AffinityIndicatorSize.large,
  showLabel: true,
  showProgress: true,
)
```

**Diálogo de Detalles**:
```dart
showAffinityDetailsDialog(context, guide, affinity);
```

## Ubicaciones en la UI

1. **Dashboard (UserCard)**: Muestra estrellas compactas debajo del avatar del guía
2. **Guide Selector**: Indicador pequeño de estrellas para cada guía
3. **Tap en Avatar**: Abre diálogo con detalles completos de afinidad

## Celebraciones de Nivel

Cuando un usuario sube de nivel:
1. Se muestra un **SnackBar** con fondo dorado
2. Icono de estrellas
3. Mensaje personalizado del nivel alcanzado
4. Duración de 4 segundos

## Futuras Mejoras

- [ ] Animación especial al alcanzar nivel 5
- [ ] Logros relacionados con afinidad
- [ ] Beneficios tangibles por nivel (descuentos en recompensas, etc.)
- [ ] Diálogos contextuales que cambien según el nivel
- [ ] Sincronización de afinidad con Firebase (opcional)
- [ ] Estadísticas comparativas entre guías
- [ ] Ritual diario en nivel 5 (meditación/reflexión matutina)

## Testing

Para probar el sistema:

1. Activar un guía
2. Completar tareas
3. Verificar que el contador aumenta
4. Alcanzar umbrales (5, 15, 30, 50, 100 tareas)
5. Verificar que el nivel sube automáticamente
6. Cerrar y reabrir la app para verificar persistencia

## Notas Importantes

- La afinidad es **por guía**, no global
- Cambiar de guía no resetea la afinidad del guía anterior
- Todos los datos se guardan localmente
- No hay límite de tiempo para alcanzar niveles
- El progreso es **aditivo**: completar más tareas siempre suma
