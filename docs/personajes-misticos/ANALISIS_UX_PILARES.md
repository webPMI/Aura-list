# Analisis UX: Relacion Pilares-Usuario

Consolidacion del analisis realizado por 5 agentes especializados.

---

## Resumen Ejecutivo

El sistema de Guias Celestiales es **arquitectonicamente solido pero funcionalmente incompleto**. Los guias existen como decoracion visual, no como companeros emocionales.

| Aspecto | Estado | Puntuacion |
|---------|--------|------------|
| Arquitectura tecnica | Excelente | 9/10 |
| Experiencia de usuario | Mejorable | 6/10 |
| Conexion emocional | Limitada | 4/10 |
| Consistencia de codigo | Aceptable | 7/10 |
| Documentacion | Parcialmente actualizada | 7/10 |

---

## Problemas Criticos Identificados

### 1. Falta de Onboarding
- Usuario abre selector y ve 21 guias sin contexto
- No hay explicacion de que es un "Guia Celestial"
- El campo `descriptionShort` no se muestra en UI
- **Impacto:** Abandono en primer contacto

### 2. Guias son Decorativos
- No hay "voz" del guia durante la jornada
- Sentencias de poder definidas pero NUNCA mostradas
- Bendiciones son genericas (mismos mensajes para todos)
- **Impacto:** Cero conexion emocional

### 3. Sinergias No Usadas
- Cada guia tiene `synergyIds` definido
- Nunca se consultan en codigo
- No hay sugerencias de guias complementarios
- **Impacto:** Profundidad desperdiciada

### 4. Selector Sobrecargado
- 21 guias en lista plana sin categorizar
- Sin filtros, busqueda ni agrupacion por `classFamily`
- Sentencias truncadas (maxLines: 1)
- **Impacto:** Paralisis de decision

### 5. Codigo Duplicado
- `_parseGuideColor()` duplicada en dashboard_screen.dart
- Fallback avatars duplicados en 2 archivos
- Patrones inconsistentes de acceso al guia activo
- **Impacto:** Deuda tecnica

---

## Plan de Mejora por Fases

### FASE 1: Fundamentos (Sprint 1-2)

#### 1.1 Refactorizaciones de Codigo
- [ ] Eliminar `_parseGuideColor()` de dashboard_screen.dart (usar `parseHexColor`)
- [ ] Crear `widgets/shared/avatar_fallback.dart` centralizado
- [ ] Estandarizar acceso al guia: siempre `activeGuideProvider`
- [ ] Propagar uso de `guideAccentColorProvider`

#### 1.2 Mejorar Selector de Guias
- [ ] Agrupar por `classFamily` (Conclave del Impetu, Arquitectos del Ciclo, etc.)
- [ ] Mostrar `descriptionShort` bajo el titulo
- [ ] Expandible para ver `powerSentence` completa
- [ ] Mostrar `affinity` visible ("Prioridad", "Descanso", etc.)

#### 1.3 Mostrar Sentencias de Poder
- [ ] En selector: modal al seleccionar guia
- [ ] En dashboard header: 2 lineas minimo (no truncar)
- [ ] Tap en sentencia abre selector

---

### FASE 2: Personificacion (Sprint 3-4)

#### 2.1 Sistema de Voces del Guia
Crear `lib/services/guide_voice_service.dart`:
```
Aethel: "El fuego del mediodia ha llegado. Aun esperas?"
Crono-Velo: "Un hilo tejido cada dia construye una armadura."
Luna-Vacia: "Tu mente necesita quietud. El silencio es fortaleza."
```

#### 2.2 Mensajes Diferenciados por Guia
Reescribir bendiciones para que cada guia celebre con su propia voz:
- Aethel: epico, fuego, urgencia
- Crono-Velo: ritmo, tejido, paciencia
- Luna-Vacia: serenidad, proteccion, descanso

#### 2.3 Momentos Rituales
- [ ] Saludo del guia al abrir la app
- [ ] Celebracion con narrativa al completar racha
- [ ] Despedida personalizada al fin del dia

---

### FASE 3: Conexion Profunda (Sprint 5-6)

#### 3.1 Sistema de Afinidad
```dart
class GuideAffinity {
  String guideId;
  int connectionLevel; // 0-5 (Extrano -> Alma Gemela)
  int tasksCompletedWithGuide;
  int daysWithGuide;
}
```

Desbloquea contenido con afinidad:
- Nivel 1: Avatar coloreado
- Nivel 2: Sentencia de Poder
- Nivel 3: Dialogos especiales
- Nivel 4: Bendiciones mejoradas
- Nivel 5: Ritual de sincronizacion diario

#### 3.2 Sinergias Activas
- [ ] Mostrar "aliados recomendados" en selector
- [ ] Sugerir guia complementario segun uso
- [ ] Vista "Constelacion" del usuario

#### 3.3 Logros Narrativos
Titulos otorgados por el guia (sin XP/puntos):
- "Primer Rayo" - Primera tarea al mediodia
- "Guardian de 3 Picos" - 3 tareas criticas
- "Amanecer Constante" - 7 dias de presencia

---

### FASE 4: Onboarding (Sprint 7)

#### 4.1 Intro Modal de Guias
```
Pantalla: "Tu Guardian Celestial"

3 cards swipeable:
1. "Afinidades" - Cada guia tiene poder en un area
2. "Bendiciones" - Activan cambios sutiles en la app
3. "Sentencias" - Frases de poder personalizadas

[Elige tu Guia] -> Abre selector mejorado
```

#### 4.2 Integracion en Welcome Screen
- [ ] Presentar sistema de guias como valor diferencial
- [ ] Seleccion opcional antes de crear cuenta

---

## Documentacion a Actualizar

### Archivos Desactualizados
1. **`implementacion-bendiciones.md`** - Necesita reescritura completa
2. **`00-todo.md` linea 75** - Aclarar Hive vs SharedPreferences
3. **`ARQUITECTURA_GUIAS_EN_APP.md`** - Documentar servicios fuera del feature

### Documentos a Crear
1. **`GUIDES_IMPLEMENTATION_GUIDE.md`** - Guia paso a paso para agregar bendiciones
2. **`GUIDE_VOICE_TEMPLATES.md`** - Plantillas de mensajes por guia

### Inconsistencias a Resolver
- Crono-Velo: ficha dice "redencion tras fracaso", codigo celebra "continuidad"
- Triggers `escudo_termico` retorna `false` (stub, no implementado)

---

## Matriz de Impacto/Esfuerzo

| Mejora | Impacto | Esfuerzo | Prioridad |
|--------|---------|----------|-----------|
| Refactorizar codigo duplicado | Bajo | Bajo | P1 |
| Agrupar selector por classFamily | Alto | Bajo | P1 |
| Mostrar descriptionShort | Alto | Bajo | P1 |
| Sentencias sin truncar | Alto | Bajo | P2 |
| Intro modal de guias | Alto | Medio | P2 |
| Mensajes diferenciados | Alto | Medio | P3 |
| Sistema de afinidad | Muy Alto | Alto | P4 |
| Sinergias activas | Medio | Medio | P5 |

---

## Archivos Clave a Crear/Modificar

### Crear
- `lib/services/guide_voice_service.dart` - Mensajes contextuales
- `lib/models/guide_affinity_model.dart` - Modelo de afinidad
- `lib/widgets/shared/avatar_fallback.dart` - Fallback centralizado
- `lib/widgets/guide_greeting_widget.dart` - Saludo del guia
- `lib/core/constants/ui_constants.dart` - Estilos centralizados

### Modificar
- `lib/screens/dashboard_screen.dart` - Eliminar _parseGuideColor
- `lib/features/guides/widgets/guide_selector_sheet.dart` - Agrupar + expandir
- `lib/services/blessing_trigger_service.dart` - Mensajes por guia
- `lib/features/guides/README.md` - Documentar integracion

---

## Conclusion

El sistema tiene un **concepto brillante** pero necesita **puente educativo y personificacion**.

Sin mejoras:
- Usuario abandona en selector (paradoja de eleccion)
- Guias son iconos bonitos sin significado

Con Fase 1+2 implementadas:
- Usuario entiende y conecta con su guia
- Bendiciones refuerzan la relacion
- App se siente viva y personalizada

**Costo estimado:** 4-6 sprints
**ROI:** Engagement mejorado + diferenciacion de mercado

