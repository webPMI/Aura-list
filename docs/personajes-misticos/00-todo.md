# Personajes Misticos - Plan de Trabajo

## Estado Actual

### Fichas Completadas (21/40) — pausa en personajes; foco en implementación
- [x] **Aethel** - El Primer Pulso del Sol (Prioridad)
- [x] **Crono-Velo** - El Tejedor del Perpetuo (Recurrencia)
- [x] **Luna-Vacia** - El Samurai del Silencio (Descanso)
- [x] **Helioforja**, **Leona-Nova**, **Chispa-Azul** — Lote 1
- [x] **Gloria-Sincro**, **Pacha-Nexo**, **Gea-Metrica** — Lote 2
- [x] **Selene-Fase**, **Viento-Estacion**, **Atlas-Orbital** — Lote 3
- [x] **Erebo-Logica**, **Anima-Suave**, **Morfeo-Astral** — Lote 4
- [x] **Shiva-Fluido**, **Loki-Error**, **Eris-Nucleo** — Lote 5
- [x] **Anubis-Vinculo**, **Zenit-Cero**, **Oceano-Bit** — Lote 6

### Recursos Visuales Existentes
- [x] Aethel - imagen base (1x1, vertical, video cute)
- [x] Aethel - videos animados (happy, aggressive, warrior mystic x4)
- [x] Crono-Velo - imagen 1x1
- [x] Auralist personalities - imagen general
- [x] Guru magic stelar person
- [ ] Luna-Vacia - pendiente generar recursos

---

## Fichas Pendientes por Crear (19/40) — pausadas; reanudar cuando se retome contenido

### Completados (21): Aethel, Crono-Velo, Luna-Vacia, Helioforja, Leona-Nova, Chispa-Azul, Gloria-Sincro, Pacha-Nexo, Gea-Metrica, Selene-Fase, Viento-Estacion, Atlas-Orbital, Erebo-Logica, Anima-Suave, Morfeo-Astral, Shiva-Fluido, Loki-Error, Eris-Nucleo, Anubis-Vinculo, Zenit-Cero, Oceano-Bit.

### Pendientes (19) — crear cuando se retome
- [ ] **Raiz-Eterea** - Conexion familiar
- [ ] **Fenix-Datos** - Recuperacion de errores
- [ ] **Boreal-Guia** - Orientacion en proyectos
- [ ] **Sombra-Espejo** - Autocritica constructiva
- [ ] **Rayo-Vibrante** - Comunicacion social
- [ ] **Cenit-Dorado** - Exito financiero/metas
- [ ] **Nebula-Mente** - Estudio y aprendizaje
- [ ] **Icaro-Vuelo** - Ambicion extrema
- [ ] **Hestia-Nexo** - Organizacion del hogar
- [ ] **Titan-Codigo** - Desarrollo tecnico
- [ ] **Oraculo-Binario** - Toma de decisiones
- [ ] **Quimera-Multi** - Multitarea controlada
- [ ] **Vesta-Llama** - Pasion y proyectos personales
- [ ] **Nix-Silencio** - Modo nocturno profundo
- [ ] **Eter-Viajero** - Tareas de viaje/desplazamiento
- [ ] **Magma-Fuerza** - Resiliencia ante el fracaso
- [ ] **Iris-Puente** - Colaboracion con otros usuarios
- [ ] **Kairos-Oportuno** - El momento perfecto para actuar
- [ ] **Aura-Final** - El espiritu de la aplicacion completa

---

## Recursos Visuales Pendientes

### Por Personaje (Formato Estandar)
Cada personaje necesita:
- [ ] Imagen 1x1 (avatar cuadrado)
- [ ] Imagen vertical (para pantallas de bienvenida)
- [ ] Video animado "idle" (estado neutral)
- [ ] Video animado "celebracion" (al completar tareas)
- [ ] Video animado "motivacion" (cuando hay tareas pendientes)

### Recursos Generales
- [ ] Imagen del panteon completo (todos los herederos)
- [ ] Mapa de sinergias entre personajes
- [ ] Animaciones de transicion entre guias

---

## Implementacion Tecnica en AuraList

### Modelo de Datos
- [x] Crear `Guide` y `BlessingDefinition` en lib/models/guide_model.dart (Arquitecto)
- [x] Campos: id, name, title, affinity, blessingIds[], synergyIds[], themePrimaryHex, blessings[]
- [x] Guardar seleccion del usuario en preferencias (activeGuideId) — activeGuideIdProvider + SharedPreferences
- [ ] (Opcional) Registrar en Hive si se necesita cache local de guias desde Firestore (typeId 8 reservado)

### Infraestructura (implementada) — Feature centralizado
- [x] **Feature Guías Celestiales:** `lib/features/guides/` — punto de entrada único `import 'package:checklist_app/features/guides/guides.dart';`
- [x] Catálogo: lib/features/guides/data/guide_catalog.dart (21 guías)
- [x] Rutas de assets: lib/features/guides/data/guide_asset_paths.dart (avatars, animaciones)
- [x] Providers: activeGuideIdProvider, activeGuideProvider, guidePrimaryColorProvider, etc.
- [x] Registro de bendiciones: lib/services/guide_blessing_registry.dart
- [x] Widgets: GuideAvatar, showGuideSelectorSheet(context)
- [x] Assets: assets/guides/avatars/ (aethel.png, crono-velo.png copiados; resto placeholder), assets/guides/animations/ (README)
- [x] Documentación: lib/features/guides/README.md, ARQUITECTURA_GUIAS_EN_APP.md

### UI Components
- [x] Widget `GuideAvatar` - muestra el heredero activo
- [x] Widget `GuideSelectorSheet` - selector de heredero (bottom sheet)
- [x] Widget `BlessingFeedback` - feedback visual al activar bendiciones
- [x] Integración en dashboard/user_card - avatar del guía visible
- [x] Sentencia de poder en greeting header del dashboard
- [ ] Widget `GuideBlessings` - muestra poderes activos (listado)
- [ ] Screen `GuideSelectionScreen` - pantalla completa de selección (opcional)

### Logica de Negocio
- [x] BlessingTriggerService - servicio para evaluar triggers de bendiciones
- [x] Providers de blessing triggers (blessingTriggerServiceProvider, etc.)
- [x] Conectar triggers al completar tarea en task_tile.dart
- [x] guideThemeDataProvider - tema dinámico basado en guía
- [x] guideLightThemeDataProvider / guideDarkThemeDataProvider
- [ ] Deteccion de patrones (burnout, rachas avanzadas)
- [ ] Integracion con notificaciones personalizadas

### Integracion con Firebase (pendiente)
- [ ] Coleccion `guides` con datos de cada heredero
- [ ] Campo `activeGuide` en documento del usuario
- [ ] Sincronizacion de preferencias de guia

---

## Proximos Pasos (Plan de Mejora UX)

Ver documento completo: `ANALISIS_UX_PILARES.md`

### Fase 1: Fundamentos (Prioridad Alta) — COMPLETADA
- [x] **Refactorizar codigo:** Eliminar _parseGuideColor de dashboard_screen (usar parseHexColor)
- [x] **Mejorar selector:** Agrupar por classFamily, mostrar descriptionShort y affinity
- [x] **Sentencias visibles:** Expandir powerSentence sin truncar (minimo 2 lineas)
- [x] **Centralizar fallback:** Crear widgets/shared/avatar_fallback.dart

### Fase 2: Personificacion (Prioridad Media) — COMPLETADA
- [x] **Voces del guia:** Crear guide_voice_service.dart con mensajes contextuales
- [x] **Mensajes diferenciados:** Cada guia celebra con su propia voz
- [x] **Momentos rituales:** Saludo al abrir app, celebracion de racha, despedida

### Fase 3: Conexion Profunda (Prioridad Baja)
- [ ] **Sistema de afinidad:** Modelo GuideAffinity (niveles 0-5)
- [ ] **Sinergias activas:** Mostrar aliados recomendados
- [ ] **Logros narrativos:** Titulos otorgados por el guia (sin XP/puntos)

### Fase 4: Onboarding
- [ ] **Intro modal:** Pantalla "Tu Guardian Celestial" con 3 cards
- [ ] **Welcome screen:** Integrar presentacion de guias

---

## Notas de Sesion

### 2026-02-12 (Sesion 4: Implementacion Fase 2 - Momentos Rituales)
- Fase 2 COMPLETADA: Todos los momentos rituales implementados
- Creado GuideGreetingWidget: saludo del guia al abrir la app (una vez por dia)
- Creado streak_provider.dart: rastreo de rachas de dias consecutivos
- Creado StreakCelebrationWidget: celebracion animada al alcanzar hitos (3, 7, 14, 21, 30 dias)
- Creado DayCycleService: deteccion de periodos del dia y transicion a noche
- Creado GuideFarewellWidget: despedida del guia al anochecer
- Creado day_cycle_provider.dart: providers para ciclo del dia
- Integrado greeting en main_scaffold.dart con GuideFarewellListener
- Integrado streak celebration en task_tile.dart al completar tareas
- flutter analyze: 0 errores (1 info en archivo de test)

### 2025-02-12 (Sesion 3: Implementacion Fase 1)
- Eliminado _parseGuideColor duplicado de dashboard_screen.dart
- Creado avatar_fallback.dart centralizado (reemplaza 2 clases duplicadas)
- Selector de guias mejorado: agrupado por classFamily, muestra affinity y descripcion
- Sentencias de poder expandidas (3 lineas, borde decorativo, interactivo)
- Creado ui_constants.dart para estilos centralizados
- Creado GuideVoiceService con mensajes personalizados por guia
- BlessingTriggerService actualizado con mensajes diferenciados por guia

### 2025-02-12 (Sesion 2: Analisis UX)
- Analisis completo con 5 agentes paralelos: UX, Journey, Documentacion, Relacion Emocional, Consistencia de Codigo
- Creado ANALISIS_UX_PILARES.md con hallazgos consolidados y plan de mejora
- Problemas criticos identificados: falta onboarding, guias decorativos, sinergias no usadas
- Plan de 4 fases definido: Fundamentos → Personificacion → Conexion → Onboarding
- Documentacion auditada: implementacion-bendiciones.md necesita reescritura
- Codigo duplicado identificado: _parseGuideColor en dashboard_screen.dart

### 2025-02-12 (Sesion 1: Implementacion)
- Análisis completo del feature con 4 agentes paralelos (estructura, integraciones, celebraciones, temas)
- Refactorizado parseHexColor a lib/core/utils/color_utils.dart (eliminado código duplicado)
- Creado BlessingTriggerService con lógica de triggers para bendiciones clave
- Creado blessing_trigger_provider.dart con providers Riverpod
- Creado guideThemeDataProvider para tema dinámico basado en guía
- Integrado GuideAvatar en dashboard/user_card
- Sentencia de poder del guía mostrada en greeting header
- Conectado BlessingFeedback al flujo de completar tarea en task_tile.dart
- Todos los archivos compilan sin errores (flutter analyze: 0 issues)

### 2025-02-11
- Revision inicial del contenido existente
- Consejo de los Pilares: Lotes 1-6 ejecutados; 21/40 fichas completadas (pausa en personajes)
- Fichas 1-3 corregidas a plantilla completa (Aethel, Crono-Velo, Luna-Vacia)
- Creados: correspondencias-mitologia-astronomia.md, guide_model.dart, implementacion-bendiciones.md
- Implementacion en app: guide_catalog.dart (21 guias), active_guide_provider.dart, guide_theme_provider.dart, guide_blessing_registry.dart, ARQUITECTURA_GUIAS_EN_APP.md

