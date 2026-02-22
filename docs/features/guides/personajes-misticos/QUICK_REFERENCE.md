# Quick Reference - Guías Celestiales

Guía rápida de consulta para el sistema de Guías Celestiales de AuraList.

---

## Estado del Sistema (2026-02-12)

| Aspecto | Estado | Detalles |
|---------|--------|----------|
| **Guías implementados** | 21/40 | 52.5% completo |
| **Fase 1 (Fundamentos)** | ✅ COMPLETADA | Selector mejorado, tema, sentencias |
| **Fase 2 (Personalización)** | ✅ COMPLETADA | Voces, rachas, momentos rituales |
| **Fase 3 (Conexión)** | ⏸️ PENDIENTE | Sistema de afinidad |
| **Fase 4 (Onboarding)** | ⏸️ PENDIENTE | CRÍTICO - implementar urgente |
| **Documentación** | ✅ EXCELENTE | 7 documentos completos |

---

## Archivos Clave

| Documento | Propósito | Cuándo Usar |
|-----------|-----------|-------------|
| **RESUMEN_EJECUTIVO.md** | Vista de alto nivel | Primera lectura |
| **GUIA_IMPLEMENTACION.md** | Paso a paso | Agregar guías/bendiciones |
| **ANALISIS_UX_PILARES.md** | Plan de mejora | Planificar sprints |
| **MEJORAS_FUTURAS.md** | Roadmap | Priorizar features |
| **VERIFICACION_CONSISTENCIA.md** | Validación | Debug, QA |
| **00-todo.md** | Plan de trabajo | Navegación docs |
| **lib/features/guides/README.md** | API técnica | Integrar en código |

---

## Comandos Rápidos

### Verificar compilación
```bash
flutter analyze
```

### Generar código (si modificas modelos)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Ejecutar app
```bash
flutter run -d chrome  # Web
flutter run -d windows # Windows
```

---

## Estructura de Datos

### Guide (21 implementados)

```dart
Guide(
  id: 'nombre-guia',           // Slug único
  name: 'Nombre-Guía',         // Nombre display
  title: 'El/La Título',       // Título épico
  affinity: 'Dominio',         // Categoría principal
  classFamily: 'Familia',      // Grupo conceptual
  powerSentence: '...',        // Frase inspiradora
  blessingIds: ['id1', 'id2'], // Bendiciones (2)
  synergyIds: ['id1', 'id2'],  // Aliados (2-3)
  themePrimaryHex: '#RRGGBB',  // Color principal
  themeSecondaryHex: '#RRGGBB',// Color secundario
  themeAccentHex: '#RRGGBB',   // Color acento
  descriptionShort: '...',     // 1-2 líneas
  mythologyOrigin: '...',      // Referencias
)
```

### BlessingDefinition (42 registradas)

```dart
BlessingDefinition(
  id: 'blessing_id',
  name: 'Nombre de Bendición',
  trigger: 'Cuándo se activa',
  effect: 'Qué hace',
)
```

---

## Familias de Clase (5 familias, 21 guías)

| Familia | Guías | Tema |
|---------|-------|------|
| **Cónclave del Ímpetu** | 4 | Acción, urgencia, prioridad |
| **Arquitectos del Ciclo** | 7 | Ritmo, constancia, planificación |
| **Oráculos del Reposo** | 5 | Calma, descanso, bienestar |
| **Oráculos del Cambio** | 3 | Flexibilidad, creatividad |
| **Oráculos del Umbral** | 3 | Privacidad, análisis, flujo |

---

## Guías Implementados (21)

### Cónclave del Ímpetu
1. **Aethel** - El Primer Pulso del Sol (Prioridad)
2. **Helioforja** - La Forja del Sol Rojo (Esfuerzo físico)
3. **Leona-Nova** - La Soberana del Ritmo Solar (Disciplina)
4. **Chispa-Azul** - El Mensajero del Relámpago (Tareas rápidas)

### Arquitectos del Ciclo
5. **Crono-Velo** - El Tejedor del Perpetuo (Recurrencia)
6. **Gloria-Sincro** - La Tejedora de Logros (Logros)
7. **Pacha-Nexo** - El Tejedor del Ecosistema Vital (Categorías)
8. **Gea-Métrica** - La Guardiana de los Hábitos (Hábitos)
9. **Viento-Estación** - El Navegante de las Estaciones (Planificación)
10. **Atlas-Orbital** - El Sustentador de la Sincronía (Sincronización)
11. **Selene-Fase** - La Tejedora del Progreso Lunar (Progreso)

### Oráculos del Reposo
12. **Luna-Vacía** - El Samurái del Silencio (Descanso)
13. **Érebo-Lógica** - El Oráculo de la Calma (Ansiedad)
14. **Ánima-Suave** - La Mensajera del Susurro (Notificaciones)
15. **Morfeo-Astral** - El Tejedor de las Notas (Notas)
16. **Selene-Fase** - La Tejedora del Progreso Lunar (Progreso)

### Oráculos del Cambio
17. **Shiva-Fluido** - El Danzante del Cambio (Cambio de planes)
18. **Loki-Error** - El Tramoyista de los Imprevistos (Imprevistos)
19. **Eris-Núcleo** - La Centella de la Creatividad (Creatividad)

### Oráculos del Umbral
20. **Anubis-Vínculo** - El Guardián del Vínculo (Privacidad)
21. **Zenit-Cero** - El Cartógrafo de las Estadísticas (Estadísticas)
22. **Océano-Bit** - El Flujo de la Fluidez Mental (Fluidez mental)

---

## Guías Pendientes Prioritarios (5 de 19)

1. **Fenix-Datos** - Recuperación de errores (referenciado en sinergias)
2. **Vesta-Llama** - Proyectos personales (referenciado en sinergias)
3. **Nebula-Mente** - Estudio y aprendizaje (nueva categoría)
4. **Magma-Fuerza** - Resiliencia ante fracaso
5. **Hestia-Nexo** - Organización del hogar

---

## Momentos Rituales (6 momentos)

| Momento | Trigger | Widget/Servicio |
|---------|---------|-----------------|
| **appOpening** | Abrir app (1x/día) | GuideGreetingWidget |
| **firstTaskOfDay** | 1ra tarea completada | BlessingTriggerService |
| **streakAchieved** | Hito racha (3,7,14...) | StreakCelebrationWidget |
| **endOfDay** | Anochecer (22:00) | GuideFarewellWidget |
| **encouragement** | Motivación general | GuideVoiceService |
| **taskCompleted** | Cualquier tarea | BlessingTriggerService |

---

## Providers Principales

```dart
// Guía activo
final guide = ref.watch(activeGuideProvider);
final guideId = ref.watch(activeGuideIdProvider);

// Colores
final primaryColor = ref.watch(guidePrimaryColorProvider);
final accentColor = ref.watch(guideAccentColorProvider);

// Voces
final message = GuideVoiceService.instance.getMessage(
  guide,
  GuideVoiceMoment.appOpening,
);

// Racha
final streak = ref.watch(currentStreakProvider);
final checkStreak = ref.read(checkStreakProvider);

// Ciclo del día
final period = ref.watch(currentPeriodProvider);
```

---

## Widgets Principales

```dart
// Avatar del guía
GuideAvatar(size: 48)

// Selector de guía
showGuideSelectorSheet(context)

// Saludo diario
GuideGreetingWidget()

// Despedida nocturna (listener)
GuideFarewellListener()

// Celebración de racha
StreakCelebrationWidget.show(context, streakDays)
```

---

## Colores de Familias

| Familia | Paleta | Ejemplos |
|---------|--------|----------|
| **Ímpetu** | Naranjas, rojos, amarillos | #E65100, #FFB300 |
| **Ciclo** | Azules, verdes, dorados | #1565C0, #388E3C, #FFD700 |
| **Reposo** | Morados, grises, plateados | #4A148C, #455A64, #B0BEC5 |
| **Cambio** | Morados, naranjas, rosas | #5E35B1, #FF8F00, #C2185B |
| **Umbral** | Negros, azules, cianes | #212121, #0277BD, #00838F |

---

## Checklist: Agregar Nuevo Guía

- [ ] Crear ficha en `docs/personajes-misticos/[N]-[nombre].md`
- [ ] Agregar a `guide_catalog.dart`
- [ ] Registrar bendiciones en `guide_blessing_registry.dart`
- [ ] Agregar voces en `guide_voice_service.dart` (6 momentos)
- [ ] Agregar avatar en `assets/guides/avatars/[id].png`
- [ ] Verificar synergyIds válidos
- [ ] Verificar blessingIds válidos
- [ ] `flutter analyze` sin errores
- [ ] Prueba manual en selector
- [ ] Actualizar `00-todo.md`

---

## Problemas Comunes y Soluciones

### "Guía no aparece en selector"
- Verificar que esté en `kGuideCatalog`
- Verificar que `id` sea único
- Verificar que `classFamily` sea válido

### "Avatar no se muestra"
- Verificar ruta en `assets/guides/avatars/[id].png`
- Verificar que `pubspec.yaml` incluya la carpeta
- Usar placeholder si no existe

### "Voces no se muestran"
- Verificar que `id` coincida con `guide.id`
- Verificar que `_messagesByGuide` tenga el guía
- Verificar que todos los 6 momentos estén cubiertos

### "Bendición no se activa"
- Verificar que `blessingId` esté en `guide.blessingIds`
- Verificar que trigger esté implementado en `BlessingTriggerService`
- Verificar logs para ver si el trigger se evalúa

---

## Métricas de Calidad

| Métrica | Objetivo | Actual | Estado |
|---------|----------|--------|--------|
| Cobertura de voces | 100% | 100% (21/21) | ✅ |
| Consistencia de IDs | 100% | 97% (3 refs pendientes) | ⚠️ |
| Documentación | 90%+ | 95% | ✅ |
| Tests unitarios | 70%+ | 0% | ❌ |
| Tests de widgets | 50%+ | 0% | ❌ |
| flutter analyze | 0 errores | 0 errores | ✅ |

---

## Prioridades Estratégicas

### 🔴 Crítico (Sprint 7-8)
- **Fase 4: Onboarding**
  - Test de afinidad inicial
  - Intro modal
  - Tutorial interactivo

### 🟠 Alta (Sprint 11-12)
- **Completar sinergias**
  - Fenix-Datos
  - Vesta-Llama

### 🟡 Media (Sprint 13-15)
- **Fase 3: Sistema de afinidad**
  - Niveles 0-5
  - Logros narrativos
  - Contenido desbloqueado

### 🟢 Baja (Sprint 16+)
- **Mejoras de UX**
  - Celebraciones temáticas
  - Vista "Constelación"
  - Widgets de sistema

---

## Contacto y Recursos

**Documentación principal:** `docs/personajes-misticos/`
**Código del feature:** `lib/features/guides/`
**Assets:** `assets/guides/`

**Para comenzar:** Lee `RESUMEN_EJECUTIVO.md`
**Para implementar:** Usa `GUIA_IMPLEMENTACION.md`
**Para planificar:** Consulta `MEJORAS_FUTURAS.md`

---

**Última actualización:** 2026-02-12
**Versión:** 1.0
